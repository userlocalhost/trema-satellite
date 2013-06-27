require 'graph/graph-db'

require 'graph/web/component'

module Graph
	module Web
		module Controller
			class PortStatsList < Graph::Web::Component
				TEMPLATE_ROOT = 'graph/web/static/port_traffic_list.erb'
				WHOLE_DAY_MINUTES = 1440

				def initialize stanza
					super stanza
				end
			
				def call env
					ret = {:body => '', :status => 404, :header => {"Content-Type" => "text/plain"}}
					param = get_param env['QUERY_STRING']
			
					case env['REQUEST_PATH']
					when @stanza[ :href ]
						ret = {:body => make_response, :status => 200}
						ret[:header] = {"Content-Type" => "text/html"}
					end
		
					return ret
				end
			
				private
				def make_response
					make_parameters
			
					erb2html TEMPLATE_ROOT
				end
			
				def erb2html path
					ERB.new( File.read( path ) ).result( binding )
				end
			
				def make_parameters
					stats = Graph::DB.query 'select dpid, portnum, rx_packets, tx_packets, rx_bytes, tx_bytes, time from portstats'

					stats = stats.reverse[0..WHOLE_DAY_MINUTES].reverse

					data_foreach_port = get_data_foreach_port stats

					@data_foreach_port = {}
					data_foreach_port.each do |key, each|

						if each.map{ |x| x.to_i }.max > 0 then
							@data_foreach_port[ key ] = {
								:min1 => get_average( each, 1 ).to_json,
								:min5 => get_average( each, 5 ).to_json,
								:min15 => get_average( each, 15 ).to_json
							}
						else
							@data_foreach_port[ key ] = { :min1 => '[1]', :min5 => '[1]', :min15 => '[1]'}
						end
					end
		
					if ! stats.empty? then
						# for setting time parameter
						@start_time = stats[0][:time]
						@last_time = stats[ stats.length - 1 ][:time]
					end

					# static parameters
					@graph_title = @stanza[ :title ]
					@top_path = @stanza[ :href ]
					@hostname = Graph::Web::Config.host
					@portnum = Graph::Web::Config.port
				end

				def get_data_foreach_port data
					ret = {}
					data.each do |each|
						hashkey = "#{ each[ :dpid ] }-#{ each[ :portnum ] }"
								
						if ! ret.has_key? hashkey then
							ret[ hashkey ] = Array.new
						end
					
						ret[ hashkey ] << each[ :rx_bytes ]
					end
	
					ret
				end
	
				def get_average data, interval
					result = []
					data.map{ |x| x.to_i }.each_slice( interval ) do |e|
						sum = e.inject { |sum, i| sum + i }

						result << ( sum / interval )
					end
	
					result
				end
			end
		end
	end
end
