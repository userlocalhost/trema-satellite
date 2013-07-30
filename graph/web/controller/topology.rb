require 'graph/graph-db'

require 'graph/web/component'

module Graph
	module Web
		module Controller
			class Topology < Graph::Web::Component

				TEMPLATE_ROOT = 'graph/web/static/topology_graph.erb'
				RECENT_COLUMNS = 50;
				THREASHOLD = 4;

				# XXX
				# This shoulud be get by config-message for each physical port.
				MAXIMUM_BANDWIDTH = ( 100000000 ) 

				def initialize stanza
					super stanza
				end
			
				def call env
					ret = {:body => '', :status => 404, :header => {"Content-Type" => "text/plain"}}
					param = get_param env['QUERY_STRING']
			
					case env['REQUEST_PATH']
					when "#{ @stanza[ :href ] }/select_path"
						ret = {:body => make_response_select_path( param ), :status => 200}
						ret[:header] = {"Content-Type" => "text/plain"}
					when @stanza[ :href ]
						ret = {:body => make_response, :status => 200}
						ret[:header] = {"Content-Type" => "text/html"}
					end
		
					return ret
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
			
				def make_parameters
					data = Graph::DB.new.query "select node_id, dpid, portnum, connection_to from ports"
			
					@nodes = get_nodes data
					@pathes = get_pathes data

					# static parameters
					@graph_title = @stanza[ :title ]
					@top_path = @stanza[ :href ]
					@hostname = Graph::Web::Config.host
					@portnum = Graph::Web::Config.port
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
						portstats = Graph::DB.new.query "select rx_packets, tx_packets, rx_bytes, tx_bytes from portstats where node_id = '#{each[:node_id]}'"
		
						if dst_node != nil then
							path = {
								:src => each[:dpid],
								:port => each[:portnum],
								:dst => dst_node[:dpid],
							}

							if option? 'heatmap' then
								current = portstats[0, RECENT_COLUMNS].inject(0) do |sum, x|
									sum + x[:rx_bytes].to_i + x[:tx_bytes].to_i
								end / RECENT_COLUMNS

								path[ :heatmap ] = {
									:cur => current,
									:max => MAXIMUM_BANDWIDTH,
									:min => 0,
								}
							end

							pathes << path
						end
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

		end
	end
end
