require 'graph/graph-route'

module Graph
	# 経路を構成する各スイッチのフローエントリ
	class Entry
		STATUS_IS_REMOVED = ( 1 << 0 );

		@@entries = []

		attr_reader :dpid, :match, :actions, :stats, :status
		attr_accessor :route_id, :route_index

		def initialize dpid, match, actions
			@dpid = dpid
			@match = match
			@actions = actions.class != Array ? [actions] : actions
			@route_id = Route::UNKNOWN_ROUTE_ID
			@route_index = -1
			@stats = Stats.new
			@status = 0

			@@entries << self
		end

		def remove
			@@entries.delete self

			# set removed-flag
			set_status STATUS_IS_REMOVED
			@route_id = Route::UNKNOWN_ROUTE_ID
			@route_index = -1

			ret = isin_db
			if ret != nil then
				db_update_entry ret[:entry_id], Time.now.strftime("%Y-%m-%d %H:%M:%S")
			end
		end

		# 当該エントリが引数で指定したエントリと結合可能かを判定する
		def is_appendable? entry
			return (! is_to_host?) && (! entry.is_from_host?) && (is_continuous? entry) && (is_necessary_condition_for? entry.match)
		end

		def is_same_match? match
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

		def insert_db_stats
			ret = isin_db
			if ret == nil then
				print "[ERROR] fail to get entry(dpid:#{@dpid}, rid:#{@route_id}) from DB\n"
				return
			end

			Graph::DB.new.query "insert into flowstats (
				entry_id,
				packet_count,
				byte_count
			) values (
				#{ret[:entry_id]},
				#{ @stats.packet_count - @stats.last_packet_count },
				#{ @stats.byte_count - @stats.last_byte_count }
			)"
		end

    def do_store_db_action entry_id, action, index = 0
			case action
			when ActionOutput
	      Graph::DB.new.query "insert into actions ( entry_id, list_index, action_type, outport )
					values ( #{entry_id}, #{index}, #{OFPAT_OUTPUT}, #{action.port_number} )"
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
			ret = isin_db

      if ret == nil then
        # Store a new entry corresponding to Entry object
        entry_id = db_insert_entry

        # Store new entries corresponding to @action
        store_db_action entry_id
			else
				db_update_entry ret[:entry_id]
      end
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
		def self.isin dpid, match, actions = nil
			@@entries.find do |each|
				( each.dpid == dpid ) && 
				( each.is_same_match? match ) && 
				( ( actions == nil ) || ( each.is_same_actions? actions ) )
			end
		end

		def self.each_match
			@@entries.each do |each|
				yield each.match
			end
		end

		class Stats
			attr_accessor :duration_sec, :duration_nsec, :priority, :idle_timeout,
				:hard_timeout, :cookie, :packet_count, :byte_count,
				:last_packet_count, :last_byte_count

			def initialize
				@duration_sec = 0
				@duration_nsec = 0
				@priority = 0
				@idle_timeout = 0
				@hard_timeout = 0
				@cookie = 0
				@packet_count = 0
				@byte_count = 0
				@last_packet_count = 0
				@last_byte_count = 0
			end
		end

		private
		def db_update_entry entry_id, removed_time = '0000-00-00 00:00:00'
			Graph::DB.new.query "update entries set
				route_id = #{@route_id},
				route_index = #{@route_index} ,
				removed_time = '#{removed_time}',
				status = #{@status} where entry_id = #{entry_id}"
		end

    def db_insert_entry
			Graph::DB.new.query "insert into entries (
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
			) values (
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
    end

    # This routine returns entry_id. If no stored entry is matched, this returns -1.
		def isin_db
			( Graph::DB.new.query "select entry_id from entries 
							where dpid = #{ @dpid } and 
								status != #{ STATUS_IS_REMOVED } and
								match_in_port = #{ @match.in_port } and
								match_dl_src = '#{ @match.dl_src.to_s }' and
								match_dl_dst = '#{ @match.dl_dst.to_s }' and
								match_dl_vlan = #{ @match.dl_vlan } and
								match_dl_vlan_pcp = #{ @match.dl_vlan_pcp } and
								match_dl_type = #{ @match.dl_type } and
								match_nw_tos = #{ @match.nw_tos } and
								match_nw_proto = #{ @match.nw_proto } and
								match_nw_src = '#{ @match.nw_src.to_s }' and
								match_nw_dst = '#{ @match.nw_dst.to_s }' and
								match_tp_src = #{ @match.tp_src } and
								match_tp_dst = #{ @match.tp_dst }" ).first
		end

		def set_status val
			@status |= val
		end

		def get_status val
			( @status & val > 0 )
		end

		def del_status val
			@status &= ~val
		end
	end
end
