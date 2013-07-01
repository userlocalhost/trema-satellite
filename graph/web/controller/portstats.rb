require 'time'
require 'uri'

require 'graph/graph-db'

require 'graph/web/component'

module Graph
	module Web
		module Controller
			class SQLCondition
				def initialize
					@conditions = Array.new
				end

				def add cond
					if cond != nil then
						@conditions << cond
					end
				end

				def to_s
					ret = 'where '
					@conditions.each do |each|
						ret += "#{each} and "
					end

					ret + '1'
				end
			end

			class PortStats < Graph::Web::Component
				TEMPLATE_ROOT = 'graph/web/static/port_traffic.erb'
				VIEW_RANGE = 60

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
						ret = {:body => make_response( param ), :status => 200}
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
							#{ param_start } < unix_timestamp(time) and 
							unix_timestamp(time) < #{ param_end }"
			
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
			
				def make_response param
					make_parameters param
			
					erb2html TEMPLATE_ROOT
				end
			
				def erb2html path
					ERB.new( File.read( path ) ).result( binding )
				end
			
				def make_parameters param
					condition = SQLCondition.new

					param_start = param.get( "time_start" )
					param_last = param.get( "time_last" )
					param_dpid = param.get( "dpid" )
					param_pnum = param.get( "pnum" ) 

					# NOTE: needs validation check of GET-parameters

					view_range = param.get( "range" ) != nil ? param.get( "range" ) : VIEW_RANGE

					condition.add "time > '#{param_start}'" if param_start != nil
					condition.add "time < '#{param_last}'" if param_last != nil
					condition.add "dpid = #{param_dpid}" if param_dpid != nil
					condition.add "portnum = #{param_pnum}" if param_pnum != nil

					sql = "select rx_packets, tx_packets, rx_bytes, tx_bytes, time from portstats #{condition.to_s}"

					stats = Graph::DB.query sql

					if param_start != nil then
						stats = stats[ 0..(view_range.to_i) ]
					else
						stats = stats.reverse[ 0..(view_range.to_i) ].reverse
					end

					make_graph_context stats

					make_graph_metainfo stats, param
				end

				def make_graph_metainfo stats, param
					param_dpid = param.get( "dpid" )
					param_pnum = param.get( "pnum" ) 

					if ! stats.empty? then
						# for setting time parameter
						@start_time = stats[0][:time]
						@last_time = stats[ stats.length - 1 ][:time]

						start_date = @start_time.split(' ')[0]
						start_time = @start_time.split(' ')[1]

						last_date = @last_time.split(' ')[0]
						last_time = @last_time.split(' ')[1]

						@graph_info = "[#{start_date}] #{start_time} - #{last_time}"
						if start_date != last_date then
							@graph_info = "[#{start_date}] #{start_time} - [#{last_date}] #{last_time}"
						end

						if param_dpid != nil then
							datapath_info = "dpid:#{param_dpid}"

							if param_pnum != nil then
								datapath_info += ", portnum:#{param_pnum}"
							end

							@graph_info += " (#{datapath_info})"
						end
					end

					# static parameters
					@graph_title = @stanza[ :title ]
					@top_path = @stanza[ :href ]
					@hostname = Graph::Web::Config.host
					@portnum = Graph::Web::Config.port
				end

				def make_graph_context stats
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
				end
			end
		end
	end
end
