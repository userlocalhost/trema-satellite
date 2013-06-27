window.onload = function() {
	var graph_array = $$('.graph_context')

	for(var i=0; i<graph_array.length; i++) {
		var elem = graph_array[i];

		elem.observe('click', function(e) {
			var elem_id = e.currentTarget.id

			console.log("[handler] " + elem_id);
		});
	}
}

PortGraph = function(w, h) {
	this.width = w;
	this.height = h;
};

PortGraph.prototype = function() {
	const GRAPH_MARGIN = 30;
	const GRAPH_MARGIN_BOTTOM = 15;

	const TITLE_HEIGHT = 15;

	const ATTR_HEIGHT = 35;
	const ATTR_MARGIN_TOP = 40;
	const ATTR_PADDING = 10;
	const ATTR_SIZE_POINT = 15;

	function get_max(data) {
		var max = 0;

		data.forEach(function(d, i) { 
			var val = Math.max.apply(null, d)
			if(max < val) {
				max = val;
			}
		});

		return max;
	}

	function draw_attrs(panel, label, color, left) {
		panel.add(pv.Bar)
				.data([1])
				.top( ATTR_PADDING )
				.left( left )
				.width( ATTR_SIZE_POINT )
				.height( ATTR_SIZE_POINT )
				.fillStyle(color)
				.strokeStyle( '#555' )
			.anchor('right').add(pv.Label)
				.left( left + ATTR_SIZE_POINT + 5 )
				.font('12px monospace')
				.textAlign('left')
				.text(label);
	}

	function draw_context(panel, input, color, width, height, max) {
		var dinput = [1, 1.2, 1.7, 1.5, .7, .5, .2];

		var fw = pv.Scale.linear(0, input.length-1).range(0, width);
		var fh = pv.Scale.linear(0, max).range(0, height);

		panel.add(pv.Line)
				.data(input)
				.bottom(function(d) { return fh(d) })
				.left(function(d) { return fw(this.index) })
				.strokeStyle( color )
				.lineWidth(2.5)
	}

	function make_graph_axis(graph, width, height, x_min, x_max, y_min, y_max) {
		var x = pv.Scale.linear(x_min, x_max).range(0, width);
		var y = pv.Scale.linear(y_min, y_max).range(0, height);
		var t_format = 'HH:mm:ss';

		// for Y-axis
		graph.add(pv.Rule)
				.data(y.ticks())
				.bottom(y)
				.strokeStyle(function(d) { return d ? "#c1c1c1" : "#000" })
		  .anchor("left").add(pv.Label)
		    .visible(function(d) { return d > 0 })
		    .text(y.tickFormat);
		
		// for X-axis
		graph.add(pv.Rule)
				.data(x.ticks(10))
				.left(x)
				.bottom(-10)
				.strokeStyle(function(d) { return d ? "#c1c1c1" : "#000" })
			.anchor('bottom').add(pv.Label)
				.textAngle(Math.PI / 8)
				.text( function(s) { return comDateFormat(new Date(s), t_format) } );
	}

	return {
		draw: function(data, title, labels, canvas) {
			var fcolor = pv.Scale.linear(0, data.length-1).range("#eacc00", "#ff0000");
			var max = get_max(data);

			var root = new pv.Panel()
				.canvas(canvas)
				.width(this.width)
				.height(this.height + TITLE_HEIGHT + ATTR_HEIGHT + GRAPH_MARGIN_BOTTOM)
				.margin(GRAPH_MARGIN);
			
			var graph = root.add(pv.Panel)
				.top(TITLE_HEIGHT)
				.width(this.width)
				.height(this.height);

			var attrs = root.add(pv.Panel)
				.top(TITLE_HEIGHT + this.height + ATTR_MARGIN_TOP)
				.width(this.width)
				.height(ATTR_HEIGHT);
		
			for(var i=0; i<data.length; i++) {
				draw_context(graph, data[i], fcolor(i), this.width, this.height, max);
			}

			var attr_unit = this.width / labels.length;
			for(var i=0; i<labels.length; i++) {
				var attr_left = ( i * attr_unit ) + ATTR_PADDING;

				draw_attrs(attrs, labels[i], fcolor(i), attr_left);
			}

			make_graph_axis(graph, this.width, this.height,
					START_TIME.getTime(), LAST_TIME.getTime(),
					0, max);

			/* set title */
			graph.add(pv.Label)
				.left(this.width / 2)
				.top(0)
				.textAlign('center')
				.font('18px monospace')
				.text(title);

			root.render();
		}
	};
}();
