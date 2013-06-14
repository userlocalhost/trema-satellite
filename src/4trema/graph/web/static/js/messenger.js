Messenger = function() {
	const REQ_SHOW_FLOWSTATS = (1 << 0);

	return {
		request: function(target, params) {
			var base_url = 'http://' + HOSTNAME + ':' + PORTNUM + BASEPATH;
			var param = '';

			for(var key in params) {
				param += key + '=' + params[key] + '&';
			}

			switch(target) {
			case REQ_SHOW_FLOWSTATS: 
				new Ajax.Request(base_url + '/get_flowstats', {
						'method': 'get',
						'parameters': param,
						onSuccess: FlowStats.showFlowStats,
						onFailure: Messenger.requestFailure
					});

				break;
			default:
			}
		},

		requestFailure: function(httpobj) {
		},

		REQ_SHOW_FLOWSTATS: REQ_SHOW_FLOWSTATS,
	};
}();
