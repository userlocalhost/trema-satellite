PortTraffic = function() {

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

	return {

	init: function(data, s_time, e_time) {
		raw_data = data;
	
		start_time = s_time;
		last_time = e_time;
	
		fcolor = pv.Scale.linear(0, raw_data.length - 1).range("#1f77b4", "#ff7f0e");
	},
	
	make_selection: function(selection, index, text) {
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
					PortTraffic.make_graph(graph_panel, raw_data, index);
	
					this.root.render();
				})
			.anchor('right').add(pv.Label)
				.left(width + text_margin)
				.font('24px monospace')
				.textAlign('left')
				.text(text);
	},
	
	make_graph_selection: function(graph) {
		var graph_range = {x:0, dx:0};
		graph.add(pv.Panel)
			.data([graph_range])
				.cursor("crosshair")
				.events("all")
				.event("mousedown", pv.Behavior.select())
				.event("select", graph)
			.add(pv.Bar)
				.left(function(d) d.x)
				.width(function(d) d.dx)
				.strokeStyle("rgba(0, 0, 0, .1)")
				.fillStyle("rgba(255, 128, 128, .4)")
				.cursor("move")
				.event("mousedown", pv.Behavior.drag())
				.event("mouseup", function(d) {
						console.log('[mouseup] ('+d.x+', '+d.dx+')');
					})
				.event("drag", graph);
	},
	
	draw_graph_context: function(panel, input, color, alpha) {
		var max = Math.max.apply(null, input);
		var min = Math.min.apply(null, input);
	
		var fw = pv.Scale.linear(0, input.length-1).range(0, SCREEN_WIDTH);
		var fh = pv.Scale.linear(0, max * 1.3).range(0, SCREEN_HEIGHT);
		
		panel.add(pv.Area)
				.data(input)
				.left(function(d) fw(this.index))
				.height(fh)
				.fillStyle(function(d) color.alpha(alpha))
				.bottom(0)
			.anchor("top").add(pv.Line)
				.fillStyle(null)
				.strokeStyle("rgba(0xc2, 0xc2, 0xc2, "+alpha+")")
				.lineWidth(2);
	},
	
	make_graph_axis: function(view, x_min, x_max, y_min, y_max) {
		var f_x = pv.Scale.linear(x_min, x_max).range(0, SCREEN_WIDTH);
		var f_y = pv.Scale.linear(y_min, y_max).range(0, SCREEN_HEIGHT);
		var t_format = 'yyyy/MM/dd HH:mm:ss';
	
		// for Y-axis
		view.add(pv.Rule)
				.data(f_y.ticks())
				.bottom(f_y)
				.strokeStyle(function(d) d ? "#c1c1c1" : "#000")
		  .anchor("left").add(pv.Label)
		    .visible(function(d) d > 0)
		    .text(f_y.tickFormat);
		
		// for X-axis
		view.add(pv.Rule)
				.data(f_x.ticks(10))
				.left(f_x)
				.strokeStyle(function(d) d ? "#c1c1c1" : "#000")
			.add(pv.Label)
				.bottom(-20)
				.textAngle( Math.PI / 8 )
				.text( function(s) comDateFormat(new Date(s), t_format) );
	},
	
	make_graph_axis_title: function(view, y_title, x_title) {
		view.add(pv.Label)
			.left(-30)
			.bottom(SCREEN_HEIGHT + 10)
			.text(x_title);
		
		view.add(pv.Label)
			.left(SCREEN_WIDTH + 10)
			.bottom(-20)
			.text(y_title);
	},
	
	make_graph: function(graph, data, index) {
		var data_array = data.map(function(x) x.input);
		var falpha = pv.Scale.linear(0, data_array.length-1).range(.2, .4);
	
		var max_value = Math.max.apply(null, data_array[index]);
		var min_value = Math.min.apply(null, data_array[index]);
		
		for(var i=0; i<data_array.length; i++) {
			if(i == index) {
				continue;
			}
		
			this.draw_graph_context(graph.add(pv.Panel), data_array[i], fcolor(i), falpha(i));
		}
	
		this.make_graph_axis(graph, start_time.getTime(), last_time.getTime(), 0, (min_value + max_value));
	
		this.make_graph_axis_title(graph, '[bytes]', '[time]');
		
		this.draw_graph_context(graph, data_array[index], fcolor(index), .9);
	
		this.make_graph_selection(graph);
	},
	
	draw: function(canvas) {
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
		
		var labels = raw_data.map(function(x) x.label);
		for(var i=0; i<labels.length; i++) {
			this.make_selection(selection, i, labels[i]);
		}
		
		graph_panel = root_panel.add(pv.Panel)
		this.make_graph(graph_panel, raw_data, SELECTION_INDEX);
		
		root.render();
	},
	
	};
	
}();
