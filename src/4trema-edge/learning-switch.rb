#
# Simple learning switch application in Ruby
#
# Author: Yasuhito Takamiya <yasuhito@gmail.com>
#
# Copyright (C) 2008-2013 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


require "trema/exact-match"
require "fdb"


#
# A OpenFlow controller class that emulates a layer-2 switch.
#
class GraphController < Controller
  add_timer_event :age_fdb, 5, :periodic


  def start
    @fdb = FDB.new
  end


  def switch_ready datapath_id
    @fdb = FDB.new

    action = SendOutPort.new( :port_number => OFPP_CONTROLLER, :max_len => OFPCML_NO_BUFFER )
    ins = ApplyAction.new( :actions => [ action ] )
    send_flow_mod_add( datapath_id,
                       :priority => OFP_LOW_PRIORITY,
                       :buffer_id => OFP_NO_BUFFER,
                       :flags => OFPFF_SEND_FLOW_REM,
                       :instructions => [ ins ]
    )
  end


  def packet_in datapath_id, message
    @fdb.learn message.eth_src, message.in_port
    port_no = @fdb.port_no_of( message.eth_dst )
    if port_no
      flow_mod datapath_id, message, port_no
      packet_out datapath_id, message, port_no
    else
      flood datapath_id, message
    end
  end


  def age_fdb
    @fdb.age
  end


  ##############################################################################
  private
  ##############################################################################


  def flow_mod datapath_id, message, port_no
    action = SendOutPort.new( :port_number => port_no )
    ins = Instructions::ApplyAction.new( :actions => [ action ] )
    send_flow_mod_add(
      datapath_id,
      :match => ExactMatch.from( message ),
      :instructions => [ ins ]
    )
  end


  def packet_out datapath_id, message, port_no
    action = Actions::SendOutPort.new( :port_number => port_no )
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => [ action ]
    )
  end


  def flood datapath_id, message
    packet_out datapath_id, message, OFPP_ALL
  end
end

require 'graph.rb'

### Local variables:
### mode: Ruby
### coding: utf-8
### indent-tabs-mode: nil
### End
