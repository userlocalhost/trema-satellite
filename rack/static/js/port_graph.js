PortTraffic = function(data, s_time, e_time) {
	this.raw_data = data;
	this.start_time = s_time;
	this.last_time = e_time;
};

PortTraffic.prototype = function() {

	const SCREEN_WIDTH = 500;
	const SCREEN_HEIGHT = 200;
	
	const MARGIN = 40;
	const MARGIN_BOTTOM = 100;
	
	const SELECTION_MARGIN_LEFT = 50;
	const SELECTION_WIDTH = 300;
	
	const SELECTION_INDEX = 2;
	
	var raw_data;
	var start_time;
	var last_time;
	var fcolor;
	var graph_panel;
	var root_panel;

	function initialize(data, s_time, e_time) {
		raw_data = data;
		start_time = s_time;
		last_time = e_time;

		fcolor = pv.Scale.linear(0, raw_data.length - 1).range("#1f77b4", "#ff7f0e");
	}
	
	function draw_graph_context(panel, input, color, alpha) {
		var max = Math.max.apply(null, input);
		var min = Math.min.apply(null, input);
	
		var fw = pv.Scale.linear(0, input.length-1).range(0, SCREEN_WIDTH);
		var fh = pv.Scale.linear(0, max * 1.3).range(0, SCREEN_HEIGHT);
		
		panel.add(pv.Area)
				.data(input)
				.left(function(d) { return fw(this.index) })
				.height(fh)
				.fillStyle(function(d) { return color.alpha(alpha) })
				.bottom(0)
			.anchor("top").add(pv.Line)
				.fillStyle(null)
				.strokeStyle("rgba(0xc2, 0xc2, 0xc2, "+alpha+")")
				.lineWidth(2);
	}
	
	function make_graph_axis(view, x_min, x_max, y_min, y_max) {
		var f_x = pv.Scale.linear(x_min, x_max).range(0, SCREEN_WIDTH);
		var f_y = pv.Scale.linear(y_min, y_max).range(0, SCREEN_HEIGHT);
		var t_format = 'yyyy/MM/dd HH:mm:ss';
	
		// for Y-axis
		view.add(pv.Rule)
				.data(f_y.ticks())
				.bottom(f_y)
				.strokeStyle(function(d) { return d ? "#c1c1c1" : "#000" })
		  .anchor("left").add(pv.Label)
		    .visible(function(d) { return d > 0 })
		    .text(f_y.tickFormat);
		
		// for X-axis
		view.add(pv.Rule)
				.data(f_x.ticks(10))
				.left(f_x)
				.strokeStyle(function(d) { return d ? "#c1c1c1" : "#000" })
			.add(pv.Label)
				.bottom(-20)
				.textAngle( Math.PI / 8 )
				.text( function(s) { return comDateFormat(new Date(s), t_format) } );
	}
	
	function make_graph_axis_title(view, y_title, x_title) {
		view.add(pv.Label)
			.left(-30)
			.bottom(SCREEN_HEIGHT + 10)
			.text(x_title);
		
		view.add(pv.Label)
			.left(SCREEN_WIDTH + 10)
			.bottom(-20)
			.text(y_title);
	}
	
	function make_graph_selection(graph) {
		var graph_range = {x:0, dx:0};
		graph.add(pv.Panel)
			.data([graph_range])
				.cursor("crosshair")
				.events("all")
				.event("mousedown", pv.Behavior.select())
				.event("select", graph)
			.add(pv.Bar)
				.left(function(d) { return d.x })
				.width(function(d) { return d.dx })
				.strokeStyle("rgba(0, 0, 0, .1)")
				.fillStyle("rgba(255, 128, 128, .4)")
				.cursor("move")
				.event("mousedown", pv.Behavior.drag())
				.event("mouseup", function(d) {
						var f_time = pv.Scale.linear(0, SCREEN_WIDTH).range(start_time.getTime(), last_time.getTime());

						params = {
							'time_start': ( f_time(d.x) / 1000 ),
							'time_end': ( f_time(d.x + d.dx) / 1000 ),
						};

						Messenger.request(Messenger.REQ_SHOW_FLOWSTATS, params);
					})
				.event("drag", graph);
	}

	function make_graph(graph, data, index) {
		var unit_label = data[index].unit;
		var data_array = data.map(function(x) { return x.input });
		var falpha = pv.Scale.linear(0, data_array.length-1).range(.2, .4);

		var max_value = Math.max.apply(null, data_array[index]);
		var min_value = Math.min.apply(null, data_array[index]);
		
		for(var i=0; i<data_array.length; i++) {
			if(i == index) {
				continue;
			}
		
			draw_graph_context(graph.add(pv.Panel), data_array[i], fcolor(i), falpha(i));
		}

		console.log("[make_graph] graph: " + graph);
		console.log("[make_graph] start_time: " + start_time);
		console.log("[make_last_time] last_time: " + last_time);
		console.log("[make_min_value] min_value: " + min_value);
		console.log("[make_max_value] max_value: " + max_value);
	
		make_graph_axis(graph, start_time.getTime(), last_time.getTime(), 0, (min_value + max_value));
	
		make_graph_axis_title(graph, '', '( '+unit_label+' )');
		
		draw_graph_context(graph, data_array[index], fcolor(index), .9);
	
		make_graph_selection(graph);
	}
	
	function make_selection(selection, index, text) {
		var height = 20;
		var width = 100;
		var base_margin = 10;
		var text_margin = 20;
	
		selection.add(pv.Bar)
				.data([index])
				.cursor("pointer")
				.top(base_margin + (index * (height + base_margin)))
				.left(base_margin)
				.width(width)
				.height(height)
				.fillStyle(fcolor(index))
				.event('click', function(index) {
					graph_panel.visible(false);
	
					graph_panel = root_panel.add(pv.Panel)
					make_graph(graph_panel, raw_data, index);
	
					this.root.render(Messenger.request);
				})
			.anchor('right').add(pv.Label)
				.left(width + text_margin)
				.font('24px monospace')
				.textAlign('left')
				.text(text);
	}

	return {
		draw: function(canvas) {
			initialize(this.raw_data, this.start_time, this.last_time);
	
			var root = new pv.Panel()
				.canvas(canvas)
				.width(SCREEN_WIDTH + SELECTION_WIDTH)
				.height(SCREEN_HEIGHT + MARGIN_BOTTOM)
				.margin(MARGIN)
			
			root_panel = root.add(pv.Panel)
				.width(SCREEN_WIDTH)
				.height(SCREEN_HEIGHT)
				.left(0)
				.strokeStyle("#ccc");
			
			var selection = root.add(pv.Panel)
				.width(SELECTION_WIDTH)
				.height(SCREEN_HEIGHT)
				.left(SCREEN_WIDTH + SELECTION_MARGIN_LEFT)
				.fillStyle("#ccc");
			
			var labels = raw_data.map(function(x) { return x.label });
			for(var i=0; i<labels.length; i++) {
				make_selection(selection, i, labels[i]);
			}
			
			graph_panel = root_panel.add(pv.Panel)
			make_graph(graph_panel, raw_data, SELECTION_INDEX);
			
			root.render();
		},
	};
	
}();
