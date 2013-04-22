function _Host(node_id, neighbor, dladdr, nwaddr) {
	//var rad = Math.PI / (Math.random() * 360);
	var rad = (Math.PI/360) * (Math.random() * 360);

	this.node_id = node_id;
	this.dladdr = dladdr;
	this.nwaddr = nwaddr;
	this.neighbor = neighbor;
	this.x = this.neighbor.x + 50 * Math.cos(rad);
	this.y = this.neighbor.y + 50 * Math.sin(rad);

	if( this.x < 0 ) {
		this.x += 100;
	} else if( this.x > Global.width ) {
		this.x -= 100;
	}

	if( this.y < 0 ) {
		this.y += 100;
	} else if( this.y > Global.height ) {
		this.y -= 100;
	}

	// statsu members
	this.type = Node.TYPE_HOST;
	this.flag = 0;

	// temporal variables to draw
	this.watering = 0;
}

_Host.prototype = {
	draw: function(p) {
		/* for test */
		var x = this.x;
		var y = this.y;

    p.stroke(0xa0, 0xa0, 0xa0);
    p.fill(255,255,255);
    p.strokeWeight(2);

		if(this.get_flag(Node.FLAG_ON_ROUTE)) {
			x -= Node.HOST_SIZE_LARGE/2;
			y -= Node.HOST_SIZE_LARGE/2;
			p.rect(x, y, Node.HOST_SIZE_LARGE, Node.HOST_SIZE_LARGE);

			if(this.watering > Node.WATERING_MAX) {
				this.watering = 0;
			}

			x -= this.watering / 2;
			y -= this.watering / 2;
			length = Node.HOST_SIZE_LARGE + this.watering;

			p.stroke(0, (1 - this.watering/Node.WATERING_MAX) * 100);
			p.noFill();
			p.rect(x, y, length, length);

			this.watering += 0.5;
		} else {
			x -= Node.HOST_SIZE_NORMAL/2;
			y -= Node.HOST_SIZE_NORMAL/2;

			p.rect(x, y, Node.HOST_SIZE_NORMAL, Node.HOST_SIZE_NORMAL);
		}
	},

	position_update_delta: function(x, y) {
		this.x += x;
		this.y += y;
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

	isin: function(x, y) {
		var ret = false;

		if(((this.x - Node.HOST_SIZE_NORMAL) < x) && (x < (this.x + Node.HOST_SIZE_NORMAL)) &&
			 ((this.y - Node.HOST_SIZE_NORMAL) < y) && (y < (this.y + Node.HOST_SIZE_NORMAL))) {
			ret = true;
		}

		return ret;
	},

	set_neighbor: function(node) {
		this.neighbor = node;
	},
};

Host = function() {
	var list = Array();
	var prev_x = 0;
	var prev_y = 0;

	return {
		create: function(node_id, neighbor_node_id, dladdr, nwaddr) {
			neighbor = Switch.get_from_nodeid(neighbor_node_id);

			host = new _Host(node_id, neighbor, dladdr, nwaddr);

			list.push(host);

			return host;
		},

		get_from_nodeid: function(node_id) {
			for(var i=0; i<list.length; i++) {
				if(list[i].node_id == node_id) {
					var host = list[i];
					return list[i];
				}
			}

			return null;
		},

		position_update: function(p) {
			for(var i=0; i<list.length; i++) {
				list[i].position_update();
			}
		},

		draw: function(p) {
			var delta_x = p.mouseX - prev_x;
			var delta_y = p.mouseY - prev_y;

			for(var i=0; i<list.length; i++) {
				list[i].draw(p);

				if(list[i].get_flag(Node.FLAG_CAPTURED)) {
					list[i].position_update_delta(delta_x, delta_y);
				}
			}

			prev_x = p.mouseX;
			prev_y = p.mouseY;
		},

		mousePressed : function(x, y) {
			for(var i=0; i<list.length; i++) {
				if(list[i].isin(x, y)) {
					prev_x = x;
					prev_y = y;

					list[i].set_flag(Node.FLAG_CAPTURED);

					break;
				}
			}
		},

		mouseReleased : function(x, y) {
			for(var i=0; i<list.length; i++) {
				list[i].del_flag(Node.FLAG_CAPTURED);
			}
		},
	};
}();
