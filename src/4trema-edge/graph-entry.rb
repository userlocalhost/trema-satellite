require 'graph-route'

module Graph
	# 経路を構成する各スイッチのフローエントリ
	class Entry
		DB_HOST = 'localhost'
		DB_USER = 'root'
		DB_PASS = 'airone'
		DB_NAME = 'graph'

		@@entries = []

		attr_reader :dpid, :match, :actions, :stats
		attr_accessor :route_id, :route_index

		def initialize dpid, match, actions
			@dpid = dpid
			@match = match
			@actions = actions.class != Array ? [actions] : actions
			@route_id = Route::UNKNOWN_ROUTE_ID
			@route_index = -1
			@stats = Stats.new

			if ! @@entries.include? self then
				@@entries << self
			end
		end

		def remove
			@@entries.delete self
		end

		# 当該エントリが引数で指定したエントリと結合可能かを判定する
		def is_appendable? entry
			# 結合条件
			#		- self -> (host) ではない &&
			#		- self -> entry という連結が可能 && 
			#		- entry が self の十分条件である場合
			
			#return (! is_to_host?) && (is_continuous? entry) && (is_necessary_condition_for? entry.match)

			ret = is_to_host?
			print "[is_appendable?] is_to_host? (#{ret})\n"
			if ret then
				return false
			end

			print "[is_appendable?] entry (#{entry})\n"

			ret = entry.is_from_host?
			print "[is_appendable?] entry.is_from_host? (#{ret})\n"
			if ret then
				return false
			end

			ret = is_continuous? entry
			print "[is_appendable?] is_continuous? (#{ret})\n"
			if ! ret then
				return false
			end

			ret = is_necessary_condition_for? entry.match
			print "[is_appendable?] is_necessary_condition? (#{ret})\n"
			if ! ret then
				return false
			end

			return true
		end

		def is_same_match? match
#			print "[is_same_match?] (in_port) #{@match.in_port} == #{match.in_port}\n"
#			print "[is_same_match?] (dl_src) #{@match.dl_src.value} == #{match.dl_src.value}\n"
#			print "[is_same_match?] (dl_dst) #{@match.dl_dst.value} == #{match.dl_dst.value}\n"
#			print "[is_same_match?] (dl_vlan) #{@match.dl_vlan} == #{match.dl_vlan}\n"
#			print "[is_same_match?] (dl_vlan_pcp) #{@match.dl_vlan_pcp} == #{match.dl_vlan_pcp}\n"
#			print "[is_same_match?] (dl_type) #{@match.dl_type} == #{match.dl_type}\n"
#			print "[is_same_match?] (nw_tos) #{@match.nw_tos} == #{match.nw_tos}\n"
#			print "[is_same_match?] (nw_proto) #{@match.nw_proto} == #{match.nw_proto}\n"
#			print "[is_same_match?] (nw_src) #{@match.nw_src.value} == #{match.nw_src.value}\n"
#			print "[is_same_match?] (nw_dst) #{@match.nw_dst.value} == #{match.nw_dst.value}\n"
#			print "[is_same_match?] (tp_src) #{@match.tp_src} == #{match.tp_src}\n"
#			print "[is_same_match?] (tp_dst) #{@match.tp_dst} == #{match.tp_dst}\n"

			return (@match.in_port == match.in_port) &&
				(@match.dl_src.value == match.dl_src.value) &&
				(@match.dl_dst.value == match.dl_dst.value) &&
				(@match.dl_vlan == match.dl_vlan) &&
				(@match.dl_vlan_pcp == match.dl_vlan_pcp) &&
				(@match.dl_type == match.dl_type) &&
				(@match.nw_tos == match.nw_tos) &&
				(@match.nw_proto == match.nw_proto) &&
				(@match.nw_src.value == match.nw_src.value) &&
				(@match.nw_dst.value == match.nw_dst.value) &&
				(@match.tp_src == match.tp_src) &&
				(@match.tp_dst == match.tp_dst)
		end

		# 当該エントリが引数で渡されたパラメータかどうかを確認
		def is_same_actions? actions
			ret = false

			print "[Entry] (is_same_actions?) actions: #{actions}"
			print "[Entry] (is_same_actions?) @actions: #{@actions}"

			if @actions.class == actions.class && @actions.length == actions.length then
				if @actions.class == Array then
					ret = @actions.zip( actions ).all? { |x, y| is_same_action? x, y }
				else
					ret = is_same_action? @actions, actions
				end
			end

			return ret
		end

		# 引数で指定した２つのアクションが同一のものかどうかのチェック
		def is_same_action? a1, a2
			ret = false

			if a1.class == a2.class then
				case a1
				when SendOutPort
					ret = a1.max_len == a2.max_len && a1.port_number == a2.port_number
				when Enqueue
					ret = a1.port_number == a2.port_number && a1.queue_id == a2.queue_id
				when SetIpAddr
					ret = a1.ip_address.to_s == a2.ip_address.to_s
				when SetVlanVid
					ret = a1.vlan_id == a2.vlan_id
				when SetIpTos
					ret = a1.type_of_service == a2.type_of_service
				when SetTransportPort
					ret = a1.port_number == a2.port_number
				when SetVlanPriority
					ret = a1.vlan_priority == a2.vlan_priority
				when SetEthAddr
					ret = a1.mac_address == a2.mac_address
				else
					ret = true
				end
			end

			return ret
		end

		# [制限事項] 
		#		- アドレス変換処理を含むアクションが設定されている場合にはうまく動作しない
		#		- IP アドレスのサブネットマスクのワイルドカードの設定が行われている場合には上手く動作しない
		def is_necessary_condition_for? match

#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_DL_VLAN}) #{match.dl_vlan} == #{@match.dl_vlan}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_DL_SRC}) #{match.dl_src} == #{@match.dl_src}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_DL_DST}) #{match.dl_dst} == #{@match.dl_dst}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_DL_VLAN_PCP}) #{match.dl_vlan_pcp} == #{@match.dl_vlan_pcp}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_DL_TYPE}) #{match.dl_type} == #{@match.dl_type}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_NW_TOS}) #{match.nw_tos} == #{@match.nw_tos}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_NW_PROTO}) #{match.nw_proto} == #{@match.nw_proto}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_NW_SRC_ALL}) #{match.nw_src} == #{@match.nw_src}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_NW_DST_ALL}) #{match.nw_dst} == #{@match.nw_dst}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_TP_SRC}) #{match.tp_src} == #{@match.tp_src}\n"
#			print "[is_necessary_condition_for?] (#{match.wildcards & Trema::Match::OFPFW_TP_DST}) #{match.tp_dst} == #{@match.tp_dst}\n"

			return ( ( match.wildcards & Trema::Match::OFPFW_DL_VLAN ) > 0 || ( match.dl_vlan == @match.dl_vlan ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_DL_SRC ) > 0 || ( match.dl_src.value == @match.dl_src.value ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_DL_DST ) > 0 || ( match.dl_dst.value == @match.dl_dst.value ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_DL_VLAN_PCP ) > 0 || ( match.dl_vlan_pcp == @match.dl_vlan_pcp ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_DL_TYPE ) > 0 || ( match.dl_type == @match.dl_type ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_NW_TOS ) > 0 || ( match.nw_tos == @match.nw_tos ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_NW_PROTO ) > 0 || ( match.nw_proto == @match.nw_proto ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_NW_SRC_ALL ) > 0 || ( match.nw_src.value == @match.nw_src.value ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_NW_DST_ALL ) > 0 || ( match.nw_dst.value == @match.nw_dst.value ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_TP_SRC ) > 0 || ( match.tp_src == @match.tp_src ) ) &&
			 ( ( match.wildcards & Trema::Match::OFPFW_TP_DST ) > 0 || ( match.tp_dst == @match.tp_dst ) )
		end

		# 当該エントリのフローが引数のエントリのフローと連続しているかの確認
		def is_continuous? entry
			out_port = get_output_portnum
			print "[is_continuous?] out_port: #{out_port}\n"

			if ! out_port then
				print "[is_appenable?] [ERROR] #{@action} has no ActionOutput in action list\n"
				return false
			end

			src_port = Graph::Port.get @dpid, out_port
			if src_port.neighbor == 0
				return false
			end

			dst_match = entry.match
			if (dst_match.wildcards & Trema::Match::OFPFW_IN_PORT) > 0
				dst_port = Graph::Port.get_from_node_id src_port.neighbor
				if ! dst_port
					return false
				end

				return dst_port.dpid == entry.dpid
			else
				dst_port = Graph::Port.get entry.dpid, dst_match.in_port

				return (dst_port.neighbor == src_port.node_id) && (dst_port.node_id == src_port.neighbor)
			end
		end

		# ホストへ流すフローエントリかどうかの判定
		def is_to_host?
			# self -> host の判定
			out_port = get_output_portnum
			if ! out_port then
				print "[is_to_host?] [ERROR] #{@action} has no ActionOutput in action list\n"
				return false
			end

			port = Graph::Port.get @dpid, out_port

			print "[is_to_host?] dpid:#{@dpid}, port:#{out_port}, neighbor:#{port.neighbor}\n"
			print "[is_to_host?] Graph::Host.isin_node_id?:#{Graph::Host.isin_node_id? port.neighbor}\n"

			return Graph::Host.isin_node_id? port.neighbor
		end

		def is_from_host?
			port = Graph::Port.get @dpid, @match.in_port

			return Graph::Host.isin_node_id? port.neighbor
		end

		def get_output_portnum
			port = nil

			case @actions
			when ActionOutput
				port = @actions.port_number
			when Array
				@actions.each do |each|
					case each
					when ActionOutput
						port = each.port_number
						break
					end
				end
			end
			
			return port
		end

    def isin_action_db?
      isin = false

      return isin
    end

    # This routine returns entry_id. If no stored entry is matched, this returns -1.
		def isin_db
			ret = -1

			sql = "select entry_id,
										match_in_port,
										match_dl_src,
										match_dl_dst,
										match_dl_vlan,
										match_dl_vlan_pcp,
										match_dl_type,
										match_nw_tos,
										match_nw_proto,
										match_nw_src,
										match_nw_dst,
										match_tp_src,
										match_tp_dst from entries where dpid = #{@dpid}"

			client = get_db_accessor
			client.query(sql).each do 
        |entry_id,\
				match_in_port,\
				match_dl_src,\
				match_dl_dst,\
				match_dl_vlan,\
				match_dl_vlan_pcp,\
				match_dl_type,\
				match_nw_tos,\
				match_nw_proto,\
				match_nw_src,\
				match_nw_dst,\
				match_tp_src,\
				match_tp_dst|

        dl_src = Mac.new match_dl_src
        dl_dst = Mac.new match_dl_dst
        nw_src = IP.new match_nw_src
        nw_dst = IP.new match_nw_dst

				match = Match.new :in_port => match_in_port.to_i > 0 ? match_in_port.to_i : nil,
					:dl_src => dl_src.value > 0 ? dl_src.to_s : nil,
					:dl_dst => dl_dst.value > 0 ? dl_dst.to_s : nil,
					:dl_vlan => match_dl_vlan.to_i > 0 ? match_dl_vlan.to_i : nil,
					:dl_vlan_pcp => match_dl_vlan_pcp.to_i > 0 ? match_dl_vlan_pcp.to_i : nil,
					:dl_type => match_dl_type.to_i > 0 ? match_dl_type.to_i : nil,
					:nw_tos => match_nw_tos.to_i > 0 ? match_nw_tos.to_i : nil,
					:nw_proto => match_nw_proto.to_i > 0 ? match_nw_proto.to_i : nil,
					:nw_src => nw_src.to_i > 0 ? nw_src.to_i : nil,
					:nw_dst => nw_dst.to_i > 0 ? nw_dst.to_i : nil,
					:tp_src => match_tp_src.to_i > 0 ? match_tp_src.to_i : nil,
					:tp_dst => match_tp_dst.to_i > 0 ? match_tp_dst.to_i : nil

        if is_same_match? match then
          ret = entry_id.to_i
          break
        end
			end

			return ret
		end

    def store_db_entry entry_id = -1
			client = get_db_accessor

			sql = "insert into entries (
				created_time, 
				dpid,
				route_id, 
				route_index,
				match_wildcards,
				match_in_port,
				match_dl_src,
				match_dl_dst,
				match_dl_vlan,
				match_dl_vlan_pcp,
				match_dl_type,
				match_nw_tos,
				match_nw_proto,
				match_nw_src,
				match_nw_dst,
				match_tp_src,
				match_tp_dst
			) value (
				now(), 
				#{@dpid}, 
				#{@route_id},
				#{@route_index},
				#{@match.wildcards},
				#{@match.in_port},
				'#{@match.dl_src.to_s}',
				'#{@match.dl_dst.to_s}',
				#{@match.dl_vlan},
				#{@match.dl_vlan_pcp},
				#{@match.dl_type},
				#{@match.nw_tos},
				#{@match.nw_proto},
				'#{@match.nw_src.to_s}',
				'#{@match.nw_dst.to_s}',
				#{@match.tp_src},
				#{@match.tp_dst}
			)"

			if entry_id > 0 then
				sql = "update entries set 
					route_id = #{@route_id},
					route_index = #{@route_index} where entry_id = #{entry_id}"
			end

			print "[store_db_entry] sql: #{sql}\n"

			stmt = client.prepare sql
				
			# execute query
			stmt.execute

      return stmt.insert_id
    end

		def create_db_stats entry_id
			store_db_stats "insert into flowstats (
				entry_id,
				duration_sec,
				duration_nsec,
				priority,
				idle_timeout,
				hard_timeout,
				cookie,
				packet_count,
				byte_count
			) value (
				#{entry_id},
				#{@stats.duration_sec},
				#{@stats.duration_nsec},
				#{@stats.priority},
				#{@stats.idle_timeout},
				#{@stats.hard_timeout},
				#{@stats.cookie},
				#{@stats.packet_count},
				#{@stats.byte_count}
			)"
		end

		def update_db_stats
			entry_id = isin_db
			if entry_id < 0 then
				print "[ERROR] fail to get entry(dpid:#{@dpid}, rid:#{@route_id}) from DB\n"
				return
			end

			store_db_stats "update flowstats set
				duration_sec = #{@stats.duration_sec},
				duration_nsec = #{@stats.duration_nsec},
				priority = #{@stats.priority},
				idle_timeout = #{@stats.idle_timeout},
				hard_timeout = #{@stats.hard_timeout},
				cookie = #{@stats.cookie},
				packet_count = #{@stats.packet_count},
				byte_count = #{@stats.byte_count} where entry_id = #{entry_id}"
		end

		def store_db_stats sql
			print "[store_db_stats] sql: #{sql}\n"

			get_db_accessor.prepare( sql ).execute
		end

    def do_store_db_action entry_id, action, index = 0
			case action
			when ActionOutput
	      sql = 'insert into actions (
	        entry_id,
	        list_index,
	        action_type,
	        outport
	      ) value (?, ?, ?, ?)'

				client = get_db_accessor
        stmt = client.prepare(sql).execute entry_id,
          index,
          OFPAT_OUTPUT,
          action.port_number
      end
    end

    def store_db_action entry_id
			case @actions
			when Array
				@actions.each_with_index do |each, i|
          do_store_db_action entry_id, each, i
				end
      else
        do_store_db_action entry_id, @action
			end
    end

		def store_db
			print "[store_db] call isin_db\n"
			entry_id = isin_db

			print "[store_db] result of isin_db: #{entry_id}\n"
      if entry_id > 0 then
				store_db_entry entry_id
			else
        # Store a new entry corresponding to Entry object
        entry_id = store_db_entry

        # Store new entries corresponding to @action
        store_db_action entry_id

				# create flow-stats table-entry
				create_db_stats entry_id
      end
		end

		def get_db_accessor
			return Mysql.connect(DB_HOST, DB_USER, DB_PASS, DB_NAME)
		end

		def self.store_db
			@@entries.each do |each|
				each.store_db
			end
		end

		# 指定した Match オブジェクト及びアクションリストが既に登録されているかをチェック
		# @return
		#		Entry オブジェクト：引数にマッチする Entry オブジェクトがある場合
		#		nil：引数にマッチする Entry オブジェクトが無い場合
		def self.isin dpid, match, actions
			@@entries.find do |each|
				(each.dpid == dpid) && (each.is_same_match? match) && (each.is_same_actions? actions)
			end
		end

		def self.each_match
			@@entries.each do |each|
				yield each.match
			end
		end

		class Stats
			attr_accessor :duration_sec, :duration_nsec, :priority, :idle_timeout,
				:hard_timeout, :cookie, :packet_count, :byte_count

			def initialize
				@duration_sec = 0
				@duration_nsec = 0
				@priority = 0
				@idle_timeout = 0
				@hard_timeout = 0
				@cookie = 0
				@packet_count = 0
				@byte_count = 0
			end
		end
	end
end
