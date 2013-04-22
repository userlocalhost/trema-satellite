Node = function() {
	const TYPE_HOST = (1 << 0);
	const TYPE_SWITCH = (1 << 1);

	const WATERING_MAX = 40;
	
	const HOST_SIZE_NORMAL = 20;
	const HOST_SIZE_LARGE = 30;

	const FLAG_CAPTURED = (1 << 0);
	const FLAG_ENFORCED = (1 << 1);
	const FLAG_WATERING = (1 << 2);
	const FLAG_ON_ROUTE = (1 << 3);

	return {
		get_from_nodeid: function(nodeid) {
			var sw = Switch.get_from_nodeid(nodeid);
			if(sw) {
				return sw;
			}

			var host = Host.get_from_nodeid(nodeid);
			if(host) {
				return host;
			}

			return null;
		},

		get_node_info: function(nodeid) {
			var node = this.get_from_nodeid(nodeid);
			var node_info;

			if(node == null) {
				node_info = "[Unknown]";
			} else if(node.type == TYPE_SWITCH) {
				node_info = "[Switch] dpid:#"+node.dpid;
			} else if(node.type == TYPE_HOST) {
				node_info = "[Host] dladdr:"+node.dladdr+", nwaddr:"+node.nwaddr;
			}
	
			return node_info;
		},

		// checking for data-structure
		TYPE_HOST: TYPE_HOST,
		TYPE_SWITCH: TYPE_SWITCH,

		// for watering
		WATERING_MAX: WATERING_MAX,

		// size definitions
		HOST_SIZE_NORMAL: HOST_SIZE_NORMAL,
		HOST_SIZE_LARGE: HOST_SIZE_LARGE,

		// flag status
		FLAG_CAPTURED: FLAG_CAPTURED,
		FLAG_ENFORCED: FLAG_ENFORCED,
		FLAG_ON_ROUTE: FLAG_ON_ROUTE,
	};
}();
