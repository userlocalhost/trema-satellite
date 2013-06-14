require 'graph/graph-node'
require 'graph/graph-route'
require 'graph/graph-entry'

require 'graph/dsl/parser'

require 'graph/web/component'
require 'graph/web/runner'

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

	def load_config config_file
		Graph::DSL::Parser.parse config_file
	end

	alias :start_orig :start if GraphController.method_defined? :start
	def start
		Graph::DB.clear

		start_orig if defined? start_orig

		pid = Graph::Web::Runner.run

		p "[start_orig] pid: #{pid}"
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

		# エントリの作成
		entry = Graph::Entry.new dpid, options[:match], options[:actions]

		# エントリを既存の unknown 経路と結合する (可能であれば)
		if ! Graph::Route.may_append_entry entry then
			# 経路の作成
			Graph::Route.create entry
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

				# store database
				port.store_db_stats each.rx_packets, each.tx_packets, each.rx_bytes, each.tx_bytes

				port.save
			when FlowStatsReply
				entry = Graph::Entry.isin dpid, each.match, each.actions

				if entry then
					entry.stats.last_packet_count = entry.stats.packet_count
					entry.stats.last_byte_count = entry.stats.byte_count

					entry.stats.packet_count = each.packet_count
					entry.stats.byte_count = each.byte_count

					entry.insert_db_stats
				else
					info "[stats_reply] (FlowStatsReply) (ERROR) fail to find Graph::Entry object"
				end
			else
				info "[stats_reply] (ERROR) #{each} is unknown stats-reply type"
			end
		end

		stats_reply_orig dpid, msg if defined? stats_reply_orig
	end

	alias :flow_removed_orig :flow_removed if GraphController.method_defined? :flow_removed
	def flow_removed dpid, msg

		entry = Graph::Entry.isin dpid, msg.match
		if entry != nil then
			Graph::Route.remove_entry entry

			entry.remove
		end

		p "[flow_removed_orig] removed an entry of (dpid:#{dpid})"

		Graph::Route.dump_unknown
		Graph::Route.dump_known

		# データベースに保存
		Graph::Entry.store_db
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
	
	Signal.trap( :INT ) do
		p "< SIGINT is redeived >"
	end
	
	Signal.trap( :TERM ) do
		p "< SIGTERM is redeived >"
	end
end
