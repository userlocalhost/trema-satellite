FlowStats = function() {
	return {
		showFlowStats: function(httpobj) {
			var context = '';
			var data;

			eval('data='+httpobj.responseText);
		
			for(var i=0; i<data.length; i++) {
				var match = data[i].match;
				var stats = data[i].stats;
				var sum_packets = 0;
				var sum_bytes = 0;
				var match_str = '';

				stats.each(function(x) { sum_packets += parseInt(x.packet_count)});
				stats.each(function(x) { sum_bytes += parseInt(x.byte_count)});
		
				for( var key in match ) {
					if( key != 'dpid' ) {
						match_str += key.replace(/^\s*/, '') + ": " + match[key] + "\n";
					}
				}
		
				context += "\
					<div class=\"entry_node\"> \
						<div class=\"meta_info\"> \
							<div class=\"leftside\"> \
								<div class=\"dpid\">dpid: " + match.dpid + "</div> \
							</div> \
							<div class=\"rightside\"> \
								<div class=\"pc\"> <span class='value'>" + sum_packets + "</span> [packets]</div> \
								<div class=\"bc\"> <span class='value'>" + sum_bytes + "</span> [bytes]</div> \
							</div> \
						</div> \
						<div class=\"match\"> \
							<pre>" + match_str + "</pre> \
						</div> \
					</div>";
			}

			$('flowstats').innerHTML = context;
		},
	};
}();
