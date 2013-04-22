function _Line(node_a, node_b) {
  this.s_id = node_a;
  this.d_id = node_b;
	this.flag = 0;
}

_Line.prototype = {
  draw : function(processing) {
		var src = Node.get_from_nodeid(this.s_id);
		var dst = Node.get_from_nodeid(this.d_id);

		processing.stroke(0);
		processing.fill(0);

		if(this.get_flag(Line.FLAG_ENFORCED)) {

			processing.strokeWeight(3);

			scale = Math.sqrt( Math.pow((dst.x - src.x), 2) + Math.pow((dst.y - src.y), 2) );
			phi_tan = Math.atan( (dst.y - src.y) / (dst.x - src.x) );

			phi = phi_tan + Math.PI;
			if( src.x <= dst.x ) {
				phi = phi_tan
			}

			x_end = dst.x;
			y_end = dst.y; 
			if(dst.type == Node.TYPE_SWITCH) {
				x_end -= Switch.NODE_RADIUS/2 * Math.cos(phi);
				y_end -= Switch.NODE_RADIUS/2 * Math.sin(phi); 
			} else if (dst.type == Node.TYPE_HOST) {
				x_end -= Node.HOST_SIZE_LARGE/2 * Math.cos(phi);
				y_end -= Node.HOST_SIZE_LARGE/2 * Math.sin(phi); 
			}

			processing.line(src.x, src.y, dst.x, dst.y);

			processing.line(x_end, y_end, 
					x_end - (30 * Math.cos(phi - Math.PI/8)), 
					y_end - (30 * Math.sin(phi - Math.PI/8)));
	
			processing.line(x_end, y_end, 
					x_end - (30 * Math.cos(phi + Math.PI/8)), 
					y_end - (30 * Math.sin(phi + Math.PI/8)));
		} else {
			processing.strokeWeight(1);
			processing.line(src.x, src.y, dst.x, dst.y);
		}
  },

	set_flag : function(val) {
		this.flag |= val;
	},
	del_flag : function(val) {
		this.flag &= ~val;
	},
	get_flag : function(val) {
		return this.flag & val;
	},

	dump: function() {
		console.log("[Line] (dump) "+this.s_id+" => "+this.d_id);
	},
};

Line = function() {
	const FLAG_ENFORCED = 1 << 0;

	var list = Array();

	return {
		draw: function(p) {
			for(var i=0; i<list.length; i++) {
				list[i].draw(p);
			}
		},

		enforce_draw: function(p) {
			for(var i=0; i<list.length; i++) {
				list[i].enforce_draw(p);
			}
		},

		create: function(s_id, d_id) {
			if(! this.get(s_id, d_id) && s_id && d_id) {
				list.push(new _Line(s_id, d_id));
			}
		},

		get: function(s_id, d_id) {
			for(var i=0; i<list.length; i++) {
				var obj = list[i];

				if((obj.s_id == s_id) && (obj.d_id == d_id)) {
					return obj;
				}
			}
			return null;
		},

		dump: function() {
			console.log("====== [Line] ======");
			for(var i=0; i<list.length; i++) {
				list[i].dump();
			}
			console.log("====================");
		},

		FLAG_ENFORCED: FLAG_ENFORCED,
	};
}();
