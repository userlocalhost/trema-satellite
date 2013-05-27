require 'rubygems'
require 'rack'
require 'time'
require 'json'
require 'erb'

require 'lib/graph-db'

require 'lib/http-util'

class TopologyGraph
	STATIC_DIR = 'static/'
	TEMPLATE_ROOT = 'static/topology_graph.erb'

	RECENT_COLUMNS = 50;
	THREASHOLD = 4;

	def call env
		ret = {:body => '', :status => 404, :header => {"Content-Type" => "text/plain"}}
		param = HttpUtil::Get.new env['QUERY_STRING']

		case env['REQUEST_PATH']
		when /^\/css\/.*/
			ret = ret_file( env )
			ret[:header] = {"Content-Type" => "text/css"}
		when /^\/js\/.*/
			ret = ret_file( env )
			ret[:header] = {"Content-Type" => "text/javascript"}
		when '/select_path'
			ret = {:body => make_response_select_path( param ), :status => 200}
			ret[:header] = {"Content-Type" => "text/plain"}
		when '/'
			ret = {:body => make_response, :status => 200}
			ret[:header] = {"Content-Type" => "text/html"}
		end

		Rack::Response.new ret[:body], ret[:status], ret[:header]
	end

	private
	def make_response_select_path param
		ret = ''
		param_start = param.get 'time_start'
		param_end = param.get 'time_end'

		return ret.to_json
	end

	def make_response
		make_parameters

		erb2html TEMPLATE_ROOT
	end

	def erb2html path
		ERB.new( File.read( path ) ).result( binding )
	end

	def ret_file env
		path = STATIC_DIR + env['REQUEST_PATH'].slice(1, env['REQUEST_PATH'].length)
		status = 200
		body = ''

		if File.exist? path
			body = File.read path
		else
			status = 404
		end

		return {:body => body, :status => status}
	end

	def make_parameters
		data = Graph::DB.query "select node_id, dpid, portnum, connection_to from ports"

		@nodes = get_nodes data
		@pathes = get_pathes data
	end

	def get_nodes data
		ret = []

		data.map{ |x| x[:dpid] }.uniq.each do |dpid|
			ports = []
			data.select{ |x| x[:dpid] == dpid }.each do |each|
				ports << each[:portnum]
			end

			ret << {
				:dpid => dpid,
				:ports => ports.to_json,
			}
		end

		return ret
	end

	def get_pathes data
		pathes = Pathes.new

		data.each do |each|
			dst_node = data.find { |x| x[:node_id] == each[:connection_to] }
			portstats = Graph::DB.query "select rx_packets, tx_packets, rx_bytes, tx_bytes from portstats where node_id = '#{each[:node_id]}'"

			maximum = portstats.map{ |x| ( x[:rx_bytes].to_i + x[:tx_bytes].to_i ) }.max
			current = portstats[0, RECENT_COLUMNS].inject(0) do |sum, x|
				sum + x[:rx_bytes].to_i + x[:tx_bytes].to_i
			end / RECENT_COLUMNS

			frequency = portstats[0, RECENT_COLUMNS].inject(0) do |sum, x|
				(( x[:rx_packets].to_i + x[:tx_packets].to_i ) > THREASHOLD ) ? sum + 1.0 : sum
			end / RECENT_COLUMNS

			pathes << {
				:src => each[:dpid],
				:port => each[:portnum],
				:dst => dst_node[:dpid],
				:cur => current,
				:max => maximum,
				:frq => frequency,
			} if dst_node != nil 
		end

		return pathes.to_array
	end

	class Pathes
		def initialize
			@path_array = []
		end

		def << p
			if ! @path_array.any? do |each|
				each[:dst] == p[:src] && each[:src] == p[:dst]
			end then
				@path_array << p
			end
		end

		def each &block
			@path_array.each { |x| block.call x }
		end

		def to_array
			@path_array
		end
	end
end
