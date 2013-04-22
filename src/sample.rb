# This sample script is locked in the conf/env.conf

require 'digest/md5'

#LONG_MAX = ( 1 << 64 ) - 1
TRANSPORT_MAX = 5

SW1_DPID = 0x1
SW2_DPID = 0x2
SW3_DPID = 0x3
SW4_DPID = 0x4
SW5_DPID = 0x5

class GraphDatapath
	attr_reader :dpid

  def initialize dpid
    @dpid = dpid
  end
end

class GraphHost
	attr_reader :name, :mac, :ip

  def initialize name, mac, ip
    @name = name
    @mac = mac
    @ip = ip
  end
end

class Timer
	def initialize(sec)
		@th = Thread.new{sleep sec; yield}
	end
	def stop
		@th.stop
	end
end

class GraphController < Controller
	@@sw_list = []

  def start
		@packet_hash = Hash.new

    host1 = GraphHost.new "host1", "00:00:00:00:00:01", "192.168.0.1"
    host2 = GraphHost.new "host2", "00:00:00:00:00:02", "192.168.0.2"
    host3 = GraphHost.new "host3", "00:00:00:00:00:03", "192.168.0.3"
    host4 = GraphHost.new "host4", "00:00:00:00:01:04", "192.168.1.4"

    sw1 = GraphDatapath.new SW1_DPID
    sw2 = GraphDatapath.new SW2_DPID
    sw3 = GraphDatapath.new SW3_DPID
    sw4 = GraphDatapath.new SW4_DPID
    sw5 = GraphDatapath.new SW5_DPID

		Thread.abort_on_exception = true
		Timer.new(5) do
			# for host1 <-> host2
			install_forwarding_rule make_forwarding_rule(host1, host2, [[sw1.dpid, 3, 1],
																																	[sw4.dpid, 3, 2],
																																	[sw2.dpid, 1, 3]])
			install_forwarding_rule make_forwarding_rule(host2, host1, [[sw1.dpid, 1, 3],
																																	[sw4.dpid, 2, 3],
																																	[sw2.dpid, 3, 1]])
	
			# for host1 <-> host3
			install_forwarding_rule make_forwarding_rule(host1, host3, [[sw1.dpid, 3, 4],
																																	[sw5.dpid, 2, 3],
																																	[sw3.dpid, 1, 2]])
			install_forwarding_rule make_forwarding_rule(host3, host1, [[sw3.dpid, 2, 3],
																																	[sw4.dpid, 1, 3],
																																	[sw1.dpid, 1, 3]])
			
			# for host2 <-> host3
			install_forwarding_rule make_forwarding_rule(host2, host3, [[sw2.dpid, 3, 2],
																																	[sw5.dpid, 1, 3],
																																	[sw3.dpid, 1, 2]])

			#it's ok
#			install_forwarding_rule make_forwarding_rule(host3, host2, [[sw3.dpid, 2, 1],
#																																	[sw5.dpid, 3, 1],
#																																	[sw2.dpid, 2, 3]])

			install_forwarding_rule make_forwarding_rule(host3, host2, [[sw3.dpid, 2, 1],
																																	[sw2.dpid, 2, 3],
																																	[sw5.dpid, 3, 1]])
		end
  end

	def switch_ready dpid
		@@sw_list << dpid
	end

	def packet_in dpid, msg
		info "[packet_in] (#{dpid}:#{msg.in_port}) #{msg.macsa.to_s} => #{msg.macda.to_s}"
	end

	private
	def make_forwarding_rule src, dst, hop_list
		hop_list.map { |x| x + [src.mac, dst.mac] }
	end

  # This methods install static flow-entry
  # from 'src' to 'dst' host
  # @params
	#  Array [
  #		dpid : datapath id [Integer],
	#		in_port  : for statical route [Integer],
	#		out_port : for statical route [Integer],
  #		src  : source MAC-address[String],
  #		dst  : destination MAC-address[String],
	#  ]
	#def install_forwarding_rule dpid, in_port, out_port, src, dst
	def install_forwarding_rule static_route
		static_route.each do |each|
			match = Match.new( :in_port => each[1],
											   :dl_src =>	each[3],
												 :dl_dst => each[4] )
	
			send_flow_mod_add( each[0],
											   :match => match,
											   :actions => [ ActionOutput.new(:port => each[2]) ] ) 
		end
	end
end

require 'graph.rb'
