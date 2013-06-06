Array.prototype.uniq = function(){
	tmp = {};tmp_arr = [];
	for( var i=0; i<this.length; i++ ){ tmp[ this[ i ] ] = i }
	for( i in tmp ){ tmp_arr.push( i ) }
	return tmp_arr;
};

Array.prototype.include = function(v) {
	for (var i in this) {
		if (this[i] == v) return true;
	}
	return false;
}

Port = function(node, portnum) {
	const PORT_RADIUS = 8;

	this.node = node;
	this.num = portnum;

	this.x = 0;
	this.y = 0;
	this.r = PORT_RADIUS;
};

Node = function(dpid) {
	const NODE_RADIUS = 20;

	this.x = 0;
	this.y = 0;
	this.dpid = dpid;
	this.r = NODE_RADIUS;
	this.status = 0;
	this.ports = new Array();
};

Node.prototype = function() {
	return {
		add: function(portnum) {
			this.ports.push(new Port(this, portnum));
		},
	};
}();

Path = function(a, b, cur, max, freq) {
	var f_color = pv.Scale.linear(0, .5, 1.0).range("blue", "yellow", "red");
	var f_weight = pv.Scale.linear(0, max).range(2, 15);

	this.pair = [a, b];
	this.quantity = f_color(freq);
	this.frequency = f_weight(cur);
};

Screen = function(w, h, v, t) {
	this.width = w;
	this.height = h;
	this.view_elem = v;
	this.title = t;
};

Screen.prototype = function() {
	const STATUS_NODE_SELECTED = (1 << 0);
	const STATUS_PATH_EMPHASIZE = (1 << 10);

	const FREQUENCY_SCALE_WIDTH = 10;
	const FREQUENCY_SCALE_HEIGHT = 100;
	const FREQUENCY_SCALE_MARGIN = 10;
	const FREQUENCY_SCALE_LEVEL = 50;

	const MARGIN_TITLE_HEIGHT = 30;

	var screen_width = 0;
	var screen_height = 0;
	var screen_element = null;
	var screen_title = '';

	var selected_path = new Array();
	var nodes = new Array();
	var lines = new Array();

	var vis_root = null;

	function initBaseInfo(w, h, e, t) {
		screen_width = w;
		screen_height = h;
		screen_element = e;
		screen_title = t;
	}

	function initPortInfo() {
		for(var i=0; i<nodes.length; i++) {
			var node = nodes[i];

			node.x = (i + 0.5) * screen_width/nodes.length;
			node.y = (50 + Math.random() * (screen_height - 100));
		}
	}

	function getNode(dpid) {
		return nodes.filter(function(x) { return ( x.dpid == dpid ) })[0];
	}

	function drawNode(panel) {
		panel.add(pv.Dot)
				.data(nodes)
				.left(function(d) { return d.x })
				.top(function(d) { return ( d.y + MARGIN_TITLE_HEIGHT) })
				.radius(function(d) { return d.r })
				.cursor("move")
				.fillStyle(function() { return this.strokeStyle().alpha(.2) })
				.event("click", eventNodeClicked)
				.event("mousedown", pv.Behavior.drag())
				.event("drag", panel)
			.anchor('right').add(pv.Label)
				.text(function(node) { return "dpid: 0x%x".replace("%x", node.dpid) });
	};

	function drawTitle(panel) {
		panel.add(pv.Label)
			.left(screen_width / 2)
			.bottom(screen_height - MARGIN_TITLE_HEIGHT)
			.textAlign("center")
			.font("30px sans-serif")
			.text(screen_title)
	}

	function drawScaleLine(panel) {
		panel.add(pv.Panel)
				.width(FREQUENCY_SCALE_WIDTH)
				.height(FREQUENCY_SCALE_HEIGHT)
				.bottom(screen_height - FREQUENCY_SCALE_HEIGHT - FREQUENCY_SCALE_MARGIN )
				.left(screen_width - FREQUENCY_SCALE_WIDTH - FREQUENCY_SCALE_MARGIN )
			.add(pv.Bar)
				.data(pv.range(0, 1, 1/FREQUENCY_SCALE_LEVEL ))
				.width( FREQUENCY_SCALE_WIDTH )
				.height(3)
				.top(function() { return ( MARGIN_TITLE_HEIGHT + this.index * (FREQUENCY_SCALE_HEIGHT / FREQUENCY_SCALE_LEVEL) ) })
				.fillStyle(pv.Scale.linear(0, .5, 1).range('red', 'yellow', 'blue'))
			.anchor("right").add(pv.Label)
				.left(-5)
				.textAlign('right')
				.text(function() { 
					if( this.index == 0 ) {
						return '高';
					} else if( this.index == ( FREQUENCY_SCALE_LEVEL - 1 ) ) {
						return '低';
					}

					return '';
				});
	}

	function drawLine(panel){
		for(var j=0; j<lines.length; j++) {
			var path = lines[j];

			panel.add(pv.Line)
				.data(path.pair)
				.left(function(d) { return d.x })
				.top(function(d) { return ( d.y + MARGIN_TITLE_HEIGHT )})
				.strokeStyle(path.quantity.alpha(.5))
				.interpolate("linear")
				.tension(0.7)
				.lineWidth(path.frequency);
		}
	};

	function drawSelectedPath(path) {
		selected_path.push(vis_root.add(pv.Line)
			.data(path.pair)
			.left(function(d) { return d.x })
			.top(function(d) { return ( d.y + MARGIN_TITLE_HEIGHT ) })
			//.strokeStyle(pv.color("rgba(0xcc, 0xcd, 0xdf, .8)"))
			.strokeStyle(path.quantity.alpha(.7))
			.interpolate("linear")
			.tension(0.5)
			.lineWidth(path.frequency + 2));
	};

	function clearSelectedPath() {
		for(var i=0; i<selected_path.length; i++) {
			var mark = selected_path[i];

			for(var j in vis_root.children) {
				var child = vis_root.children[j];

				if(mark == child) {
					vis_root.children.splice(j, 1);
				}
			}
		}

		selected_path = [];
	};

	function eventNodeClicked(node) {
		var selections = lines.filter(function(path) {
			return path.pair.include(node);
		});
	
		drawScreen(selections);
	};

	function drawScreen(s) {
		var selections = ( s === undefined ) ? [] : s;

		vis_root = new pv.Panel()
			.canvas(screen_element)
			.width(screen_width)
			.height(screen_height);

		drawScaleLine(vis_root);

		for(var i=0; i<selections.length; i++) {
			var path = selections[i];
			var a_id = path.pair[0].dpid;
			var b_id = path.pair[1].dpid;

			drawSelectedPath(path);
		}

		drawLine(vis_root);

		drawNode(vis_root);
		
		drawTitle(vis_root);
		
		vis_root.render();
	};
	
	return {
		add: function(dpid, ports) {
			var node = new Node(dpid);
	
			for(var i=0; i<ports.length; i++) {
				node.add(ports[i]);
			}
	
			nodes.push(node);
		},
	
		draw: function() {
			initBaseInfo(this.width, this.height, this.view_elem, this.title);
			initPortInfo();

			drawScreen();
		},

		path: function(a_id, b_id, crr, max, freq) {
			var a_node = getNode(a_id);
			var b_node = getNode(b_id);

			if( a_node != undefined && b_node != undefined ) {
				var path = new Path(a_node, b_node, crr, max, freq)
				lines.push( path );

				//lines.push(new Path(a_node, b_node, crr, max));
			}
		}
	};
}();
