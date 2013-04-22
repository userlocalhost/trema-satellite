function _Switch(dpid, x, y, size) {
	this.dpid = dpid;
  this.x = x;
  this.y = y;
  this.size = size;
  this.flag = 0;
	this.ports = Array();
	this.type = Node.TYPE_SWITCH;

	// These are used when this node scribes a host.
	this.nw_addr = null;
	this.dl_addr = null;

	// for temporal variable to draw
	this.watering = 0;
}

_Switch.prototype = {
	_draw: function(proc, x, y, size, is_watering) {

    //proc.stroke(0xc9, 0xc9, 0xc9);
    proc.stroke(0xa0, 0xa0, 0xa0);
    proc.fill(255,255,255);

    proc.strokeWeight(2);
    proc.ellipse(x, y, size, size);

		if(is_watering) {
			if(this.watering > Node.WATERING_MAX) {
				this.watering = 0;
			}
	
			radius = size + this.watering;
	
			proc.stroke(0, (1 - this.watering/Node.WATERING_MAX) * 100);
	
			proc.noFill();
			proc.ellipse(x, y, radius, radius);
	
			this.watering += 0.5;
		}
	},

  draw: function(proc) {
		if(this.get_flag(Node.FLAG_ENFORCED | Node.FLAG_ON_ROUTE)) {
			this._draw(proc, this.x, this.y, this.size, true);
		} else {
			this._draw(proc, this.x, this.y, this.size/2, false);
		}
  },

	isin : function(x, y) {
		var ret = false;

		if(((this.x - this.size/2) < x) && (x < (this.x + this.size/2)) &&
			 ((this.y - this.size/2) < y) && (y < (this.y + this.size/2))) {
			ret = true;
		}

		return ret;
	},

	update : function(x, y) {
		this.x = x;
		this.y = y;
	},
	
	set_node: function(node_id, portnum, neighbor) {
		this.ports[node_id] = { 'port':portnum, 'neighbor':neighbor };
	},

	get_node: function(node_id) {
		return this.ports[node_id];
	},

	set_flag : function(val) {
		this.flag |= val;
	},
	del_flag : function(val) {
		this.flag &= ~val;
	},
	get_flag : function(val) {
		return (this.flag & val) > 0;
	},

	dump : function() {
		console.log("====( dump )====");
		console.log("(x, y) = ("+this.x+", "+this.y+")");
		console.log("size : " + this.size);
		console.log("flag : " + this.flag);
		console.log("================");
	}
};

Switch = function() {
	const NODE_RADIUS = 30;
	
	const DEFAULT_SERVER_URL = "http://vmtrema:3000/graph";

	var list = Array();
	var clicked_x = 0;
	var clicked_y = 0;

	// These parameters describe where the output shows
	var content_switch_info= null;
	var title_switch_info= null;

	var server_url = DEFAULT_SERVER_URL;

	return {
		create : function(dpid, x, y) {
			var node = new _Switch(dpid, x, y, NODE_RADIUS);

			list.push(node);

			return node;
		},

		draw : function(proc) {
			for(var i=0; i<list.length; i++) {
				if(list[i].get_flag(Node.FLAG_CAPTURED)) {
					list[i].update(proc.mouseX, proc.mouseY);
				}

				list[i].draw(proc);
			}
		},

		get_from_dpid : function(dpid) {
			var node = null;

			for(var i=0; i<list.length; i++) {
				if(list[i].dpid == dpid) {
					node = list[i];
				}
			}

			return node;
		},

		get_from_nodeid : function(node_id) {
			var node = null;

			for(var i=0; i<list.length; i++) {
				if(list[i].get_node(node_id) != undefined) {
					node = list[i];
				}
			}

			return node;
		},

		clearEnforcement: function() {
			for(var i=0; i<list.length; i++) {
				list[i].del_flag(Node.FLAG_ENFORCED);
			}
		},

		setTitleSwitchInfo: function(elem) {
			title_switch_info = elem;
		},

		setContentSwitchInfo: function(elem) {
			content_switch_info = elem;
		},

		mouseClicked: function(x, y) {
		},

		mousePressed : function(x, y) {
			clicked_x = x;
			clicked_y = y;

			/*
			for(var i=0; i<list.length; i++) {
				list[i].del_flag(Node.FLAG_ENFORCED);
			}
			*/

			for(var i=0; i<list.length; i++) {
				if(list[i].isin(x, y)) {
					list[i].set_flag(Node.FLAG_ENFORCED | Node.FLAG_CAPTURED);
					break;
				}
			}
		},

		mouseReleased : function(x, y) {
			for(var i=0; i<list.length; i++) {
				if(list[i].get_flag(Node.FLAG_CAPTURED)) {
					list[i].del_flag(Node.FLAG_CAPTURED);
				}

				if(! is_clicked(x, y)) {
					list[i].del_flag(Node.FLAG_ENFORCED);
				} else if(list[i].get_flag(Node.FLAG_ENFORCED)) {
					get_switch_info(list[i].dpid);
				}
			}
		},

		NODE_RADIUS: NODE_RADIUS,
	};

	function is_clicked(x, y) {
		return (Math.abs(x - clicked_x) < 10) && (Math.abs(y - clicked_y) < 10)
	}

	function get_switch_info(dpid) {
		if(title_switch_info != null) {
			title_switch_info.innerHTML = "(dpid: #"+ dpid +")";
		}

		new Ajax.Request(Server.base_url() + "/get_switch_info/" + dpid, {
			"method":"get",
			onComplete: function(request) {
				var switches = eval(request.responseText);
				var str_context = "";
				
				for(var i=0; i<switches.length; i++) {
					var swinfo = switches[i]["port"];
					var node_info = Node.get_node_info(swinfo['connection_to']);

					str_context += "Port: "+swinfo["portnum"]+"\n";
					str_context += "　- connection_to: "+node_info+"\n";
					str_context += "　- tx_packets: "+swinfo["tx_packets"]+"\n";
					str_context += "　- rx_packets: "+swinfo["rx_packets"]+"\n";
					str_context += "　- tx_bytes: "+swinfo["tx_bytes"]+"\n";
					str_context += "　- rx_bytes: "+swinfo["rx_bytes"]+"\n\n";
				}

				//content_switch_info.innerHTML = request.responseText;
				if(content_switch_info != null) {
					content_switch_info.innerHTML = str_context;
				}
			},

			onFailure: function(request) {
			},
		});
	}
}();
