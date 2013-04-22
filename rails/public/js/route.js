/*
 * the entry consists on an Array of Switch-id [Integer].
 * */
function _Route(route_id, entries, path) {
	this.route_id = route_id;

	/* entries contain 'dpid' and 'entry_id' */
	this.entries = entries;
	this.path = path;
	this.flag = 0;
}

_Route.prototype = {
	dump: function() {
		for(var i=0; i<this.entries.length; i++) {
			var node_id = this.entries[i]['dpid'];
			var node = Switch.get(node_id);
		}
	},

	do_enforce: function() {
		// enforce lines

		for(var i=0; i<this.path.length; i+=2) {
			var line = Line.get(this.path[i], this.path[i+1]);

			if(line) {
				line.set_flag(Line.FLAG_ENFORCED);
			}
		}

		// enforce nodes
		for(var i=0; i<this.entries.length; i++) {
			var node = Switch.get_from_dpid(this.entries[i]['dpid']);

			if(node) {
				node.set_flag(Node.FLAG_ON_ROUTE);
			}
		}

		// enforce hosts
		var src_host = Host.get_from_nodeid(this.path[0]);
		var dst_host = Host.get_from_nodeid(this.path[this.path.length - 1]);

		src_host.set_flag(Node.FLAG_ON_ROUTE)
		dst_host.set_flag(Node.FLAG_ON_ROUTE)
	},

	clear_enforce: function() {
		// clear enforcese of lines
		for(var i=0; i<this.path.length; i+=2) {
			var line = Line.get(this.path[i], this.path[i+1]);

			if(line) {
				line.del_flag(Line.FLAG_ENFORCED);
			}
		}

		// clear enforcese of nodes
		for(var i=0; i<this.entries.length; i++) {
			var node = Switch.get_from_dpid(this.entries[i]['dpid']);

			if(node) {
				node.del_flag(Node.FLAG_ON_ROUTE);
			}
		}

		// clear enforces of hosts
		var src_host = Host.get_from_nodeid(this.path[0]);
		var dst_host = Host.get_from_nodeid(this.path[this.path.length - 1]);

		src_host.del_flag(Node.FLAG_ON_ROUTE)
		dst_host.del_flag(Node.FLAG_ON_ROUTE)
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
};

Route = function() {
	const FLAG_SELECTED = (1 << 0);

	var list = new Array();
	var content_entry_info = null;

	return {
		create: function(route_id, entries, path) {
			for(var i=0; i<path.length; i+=2) {
				Line.create(path[i], path[i+1]);
			}

			list.push(new _Route(route_id, entries, path));
		},

		total: function() {
			return list.length;
		},

		get: function(route_id) {
			for(var i=0; i<list.length; i++) {
				if(list[i].route_id == route_id) {
					return list[i];
				}
			}

			return null;
		},

		setContentEntriesInfo: function(elem) {
			content_entry_info = elem;
		},

		preDraw: function(p) {
			var enforce_route = null;

			// clear enforcement
			for(var i=0; i<list.length; i++) {
				if(list[i].get_flag(FLAG_SELECTED)) {
					enforce_route = list[i];
				}
			}

			if(enforce_route) {
				enforce_route.do_enforce();
			}
		},

		dump: function() {
			console.log("====== [Route] ======");
			for(var i=0; i<list.length; i++) {
				list[i].dump();
			}
			console.log("=====================");
		},

		select: function(route_id) {
			for(var i=0; i<list.length; i++) {
				list[i].del_flag(FLAG_SELECTED);
				list[i].clear_enforce();
			}

			Switch.clearEnforcement();

			route = this.get(route_id);
			if(route) {
				route.set_flag(FLAG_SELECTED);
			}

			this.get_route_info(route_id);
		},

		get_route_info: function(route_id) {
			route = this.get(route_id);
			param_entry_id = "";

			if(content_entry_info == null || route == null) {
				return ;
			}

			for(var i=0; i<route.entries.length; i++) {
				if(i > 0) {
					param_entry_id += ":"
				}

				param_entry_id += route.entries[i]['entry_id'];
			}

			new Ajax.Request(Server.base_url() + "/get_route_info/", {
				"method":"post",
				"parameters":"entry_id=" + param_entry_id,
				onComplete: function(request) {
					var entries = eval(request.responseText);
					var str_context = "";

					for(var i=0; i<entries.length; i++) {
						var entry = entries[i]['entry']['entry'];
						var actions = entries[i]['actions'];

						str_context += "Entry: (dpid: "+entry['dpid']+")\n";
						str_context += "　- in_port			: "+entry['match_in_port']+"\n";
						str_context += "　- dl_src			: "+entry['match_dl_src']+"\n";
						str_context += "　- dl_dst			: "+entry['match_dl_dst']+"\n";
						str_context += "　- dl_vlan			: "+entry['match_dl_vlan']+"\n";
						str_context += "　- dl_vlan_pcp	: "+entry['match_dl_vlan_pcp']+"\n";
						str_context += "　- dl_type			: "+entry['match_dl_type']+"\n";
						str_context += "　- nw_src			: "+entry['match_nw_src']+"\n";
						str_context += "　- nw_dst			: "+entry['match_nw_dst']+"\n";
						str_context += "　- tp_src			: "+entry['match_tp_src']+"\n";
						str_context += "　- tp_dst			: "+entry['match_tp_dst']+"\n";
						str_context += "　- wildcards		: "+entry['match_wildcards']+"\n";

						for(var j=0; j<actions.length; j++) {
							action = actions[j]["action"];

							if(action['action_type'] == 0) {
								var to_node = Node.get_node_info(action['connection_to']);

								str_context += "　　- action["+action['list_index']+"]\n";
								str_context += "　　- action_type: (OFPUT_OUTPUT)\n";
								str_context += "　　- outport:"+action['outport']+"\n";
								str_context += "　　　- "+ to_node +"\n\n";
							}
						}
					}

					content_entry_info.innerHTML = str_context;
				},
	
				onFailure: function(request) {
				},
			});
		},

		unselect: function(route_id) {
			route = this.get(route_id);

			if(route) {
				route.del_flag(FLAG_SELECTED);
			}
		},
	};
}();
