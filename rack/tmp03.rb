require 'rubygems'
require 'rack'
require 'time'
require 'json'
require 'erb'

require 'lib/graph-db'
require 'lib/log'

require 'lib/http-util'

class TmpApp
	STATIC_DIR = 'static/'
	TEMPLATE_ROOT = 'static/sample.erb'
	FILE_PORT_TRAFFIC = 'static/js/port_traffic.js'

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
		when '/get_flowstats'
			ret = {:body => make_response_get_flowstats( param ), :status => 200}
			ret[:header] = {"Content-Type" => "text/plain"}
		when '/'
			ret = {:body => make_response, :status => 200}
			ret[:header] = {"Content-Type" => "text/html"}
		end

		Rack::Response.new ret[:body], ret[:status], ret[:header]
	end

	private
	def make_response_get_flowstats param
		ret = ''
		param_start = param.get 'time_start'
		param_end = param.get 'time_end'

		if param_start != nil && param_end != nil
			data = Graph::DB.query(
				"select entry_id, packet_count, byte_count, time from flowstats where 
					#{ param_start[:value] } < unix_timestamp(time) and 
					unix_timestamp(time) < #{ param_end[:value] }"
				)

			ret = data.map { |x| x[:entry_id].to_i }.uniq.map do |id|
				{ 
					:id => id,
					:data => data.select{ |entry| entry[:entry_id].to_i == id }.each{ |x| x.delete(:entry_id) }
				}
			end
		end

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
		@file_port_traffic = File.read FILE_PORT_TRAFFIC
		stats = Graph::DB.query 'select rx_packets, tx_packets, rx_bytes, tx_bytes, time from portstats where dpid = 1 and portnum = 1 limit 200'

		# for setting context parameter
		@portstats = []
		[:rx_packets, :tx_packets, :rx_bytes, :tx_bytes].each do |label|
			@portstats << { :label => label, :input => stats.map { |stat| stat[ label.to_sym ] } }
		end

		# for setting time parameter
		@start_time = stats[0][:time]
		@last_time = stats[ stats.length - 1 ][:time]
	end
end

