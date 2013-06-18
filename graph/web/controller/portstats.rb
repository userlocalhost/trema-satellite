require 'graph/graph-db'

require 'graph/web/component'

module Graph
	module Web
		module Controller
			class PortStats < Graph::Web::Component
				TEMPLATE_ROOT = 'graph/web/static/port_traffic.erb'

				def initialize stanza
					super stanza
				end
			
				def call env
					ret = {:body => '', :status => 404, :header => {"Content-Type" => "text/plain"}}
					param = get_param env['QUERY_STRING']
			
					case env['REQUEST_PATH']
					when "#{ @stanza[ :href ] }/get_flowstats"
						ret = {:body => make_response_get_flowstats( param ), :status => 200}
						ret[:header] = {"Content-Type" => "text/plain"}
					when @stanza[ :href ]
						ret = {:body => make_response, :status => 200}
						ret[:header] = {"Content-Type" => "text/html"}
					end
		
					return ret
				end
			
				private
				def make_response_get_flowstats param
					ret = ''
					param_start = param.get 'time_start'
					param_end = param.get 'time_end'
			
					if param_start != nil && param_end != nil

						data = Graph::DB.query "select entry_id, packet_count, byte_count, time from flowstats where 
							#{ param_start[:value] } < unix_timestamp(time) and 
							unix_timestamp(time) < #{ param_end[:value] }"
			
						ret = data.map { |x| x[:entry_id].to_i }.uniq.map do |id|
							{ 
								:entry_id => id,
								:stats => data.select{ |entry| entry[:entry_id].to_i == id }.each{ |x| x.delete(:entry_id) },
								:match => Graph::DB.query( "select dpid, match_wildcards, match_in_port, match_dl_src, match_dl_dst, match_dl_vlan, match_dl_vlan_pcp, match_dl_type, match_nw_tos, match_nw_proto, match_nw_src, match_nw_dst, match_tp_src, match_tp_dst from entries where entry_id = #{ id }" )[0] ,
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
			
				def make_parameters
					stats = Graph::DB.query 'select rx_packets, tx_packets, rx_bytes, tx_bytes, time from portstats where dpid = 1 and portnum = 1'

					stats = stats.reverse[0..20].reverse
			
					# for setting context parameter
					@portstats = []
					[ {:label => :rx_packets, :unit => 'packets'}, 
						{:label => :tx_packets, :unit => 'packets'}, 
						{:label => :rx_bytes, :unit => 'bytes'}, 
						{:label => :tx_bytes, :unit => 'bytes'}
					].each do |each|
						@portstats << { 
							:unit => each[:unit],
							:label => each[:label],
							:input => stats.map { |stat| stat[ each[:label].to_sym ] } 
						}
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
			end

		end
	end
end
