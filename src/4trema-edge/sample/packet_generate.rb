# -*- encoding: utf-8 -*-

class PacketGenerator < Controller
	LONG_MAX = ( 1 << 64 ) - 1
	SHORT_MAX = ( 1 << 16 ) - 1

	def switch_ready dpid
    action = SendOutPort.new( :port_number => OFPP_CONTROLLER, :max_len => OFPCML_NO_BUFFER )
    ins = ApplyAction.new( :actions => [ action ] )
    send_flow_mod_add( dpid,
                       :priority => OFP_LOW_PRIORITY,
                       :buffer_id => OFP_NO_BUFFER,
                       :flags => OFPFF_SEND_FLOW_REM,
                       :instructions => [ ins ]
    )

		send_discover_request dpid
	end

	def packet_in dpid, msg
		info "[PacketGenerator] packet_in: #{dpid}"
	end

	private
	def create_payload byte
		'00' * byte
	end

	def create_discover_request_frame dpid
		info "[create_discover_request_frame] dpid: #{dpid}"
		# dpid( 8byte ) + padding( 4byte ) + type( 2byte )
		sprintf( "%016x", dpid & LONG_MAX ) + "00000000ffff"
	end

	def send_discover_request dpid
		action = Actions::SendOutPort.new :port_number => OFPP_ALL

		data_str = create_discover_request_frame( dpid ) + create_payload( 50 )

		match = Match.new :in_port => OFPP_CONTROLLER

		msg = Trema::Messages::PacketIn.new :datapath_id => dpid, :match => match, 
			:buffer_id => OFP_NO_BUFFER, 
			:data => data_str.scan(/../).map{ |x| x.hex }

		send_packet_out( dpid,
			:packet_in => msg,
			:actions => [ action ] )
	end
end
