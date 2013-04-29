require 'graph-node'
require 'graph-route'
require 'graph-entry'

class Intervals
	def initialize(interval, &block)
		@th = Thread.new { self.main_loop }

		@block = block
		@interval = interval
		@last_count = 1
	end

	def main_loop
		while true
			sleep 1

			@last_count += 1
			if @last_count > @interval then
				@last_count = 1
				Thread.new { @block.call }
			end
		end
	end

	def join
		@th.join
	end

	def stop
		@th.stop
	end
end

class GraphController
	LONG_MAX = ( 1 << 64 ) - 1
	SHORT_MAX = ( 1 << 16 ) - 1

	PORT_STATS_INTERVAL = 5
	FLOW_STATS_INTERVAL = 5

	alias :start_orig :start if GraphController.method_defined? :start
	def start
		Graph::DB.clear

		start_orig if defined? start_orig
	end

	alias :switch_ready_orig :switch_ready if GraphController.method_defined? :switch_ready
	def switch_ready dpid
		# send OpenFlow messages to the switch for investigating
		Intervals.new PORT_STATS_INTERVAL do
			send_message dpid, PortStatsRequest.new
		end

		Intervals.new FLOW_STATS_INTERVAL do
			Graph::Entry.each_match do |match|
				send_message dpid, FlowStatsRequest.new( :match => match )
			end
		end

		send_discover_request dpid

		switch_ready_orig dpid if defined? switch_ready_orig
	end

	alias :send_flow_mod_add_orig :send_flow_mod_add if GraphController.method_defined? :send_flow_mod_add
	def send_flow_mod_add dpid, options

		entry = Graph::Entry.isin dpid, options[:match], options[:actions]
		if ! entry then
			# エントリの作成
			entry = Graph::Entry.new dpid, options[:match], options[:actions]
		end

		# エントリを既存の unknown 経路と結合する (可能であれば)
		if ! Graph::Route.may_append_entry entry then
			# 経路の作成
			route = Graph::Route.new entry

			# unknown 経路に設定
			route.set_unknown
		end

		Graph::Route.may_append_route

		Graph::Route.dump_unknown
		Graph::Route.dump_known

		# データベースに保存
		Graph::Entry.store_db

		send_flow_mod_add_orig dpid, options if defined? send_flow_mod_add_orig
	end

	alias :packet_in_orig :packet_in if GraphController.method_defined? :packet_in
	def packet_in dpid, msg
		if msg.eth_type == 0xffff
			send_discover_response dpid, msg.in_port
		elsif msg.eth_type == 0xfffe
			from_dpid = get_dpid( msg.macsa, msg.macda )
			from_port = get_portnum( msg.macsa, msg.macda )

			current_port = Graph::Port.get dpid, msg.in_port
			from_portobj = Graph::Port.get from_dpid, from_port
			if current_port.neighbor == 0
				current_port.set_neighbor from_portobj.node_id
			end

			if from_portobj.neighbor == 0
				from_portobj.set_neighbor current_port.node_id
			end
		else
			if ! Graph::Host.isin? msg.macsa
				port = Graph::Port.get dpid, msg.in_port
				host = Graph::Host.new msg.macsa.to_s, msg.ipv4_saddr.to_s, port.node_id

				host.regist
				host.store_db

				if port.neighbor == 0
					port.set_neighbor host.node_id
				end
			end

			packet_in_orig dpid, msg if defined? packet_in_orig
		end
	end

	alias :stats_reply_orig :stats_reply if GraphController.method_defined? :stats_reply
	def stats_reply dpid, msg
		msg.stats.each do |each|
			case each
			when PortStatsReply
				port = Graph::Port.get dpid, each.port_no
				port.rx_packets = each.rx_packets
				port.tx_packets = each.tx_packets
				port.rx_bytes = each.rx_bytes
				port.tx_bytes = each.tx_bytes

				# store database
				port.store_db
			when FlowStatsReply
				entry = Graph::Entry.isin dpid, each.match, each.actions

				if entry then
					entry.stats.duration_sec = each.duration_sec
					entry.stats.duration_nsec = each.duration_nsec
					entry.stats.priority = each.priority
					entry.stats.idle_timeout = each.idle_timeout
					entry.stats.hard_timeout = each.hard_timeout
					entry.stats.cookie = each.cookie
					entry.stats.packet_count = each.packet_count
					entry.stats.byte_count = each.byte_count

					entry.update_db_stats
				else
					info "[stats_reply] (FlowStatsReply) (ERROR) fail to find Graph::Entry object"
				end
			else
				info "[stats_reply] (ERROR) #{each} is unknown stats-reply type"
			end
		end

		stats_reply_orig dpid, msg if defined? stats_reply_orig
	end

	private
	def create_discover_request_frame dpid
		sprintf( "%016x", dpid & LONG_MAX ) + "00000000ffff"
	end

	def create_discover_response_frame dpid, portnum
		sprintf( "%016x", dpid & LONG_MAX ) + sprintf( "%08x", portnum & SHORT_MAX ) + "fffe"
	end

	def create_payload byte
		'00' * byte
	end

	def send_discover_request dpid
		3.times do
			send_packet_out dpid,
				:actions => ActionOutput.new( :port => OFPP_FLOOD ),
				:data => [ create_discover_request_frame( dpid ) + create_payload( 50 ) ].pack( "H*" )
		end
	end

	def send_discover_response dpid, portnum
		3.times do
			send_packet_out dpid,
				:actions => ActionOutput.new( :port => portnum ),
				:data => [ create_discover_response_frame( dpid, portnum ) + create_payload( 50 ) ].pack( "H*" )
		end
	end

	def get_dpid macsa, macda
		( macda.to_s.split(':') + macsa.to_s.split(':') )[0..7].join.hex
	end

	def get_portnum macsa, macda
		( macda.to_s.split(':') + macsa.to_s.split(':') )[8..11].join.hex
	end
end
