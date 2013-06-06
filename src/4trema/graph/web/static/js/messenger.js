Messenger = function() {
	const REQ_SHOW_FLOWSTATS = (1 << 0);

	return {
		request: function(target, params) {
			switch(target) {
			case REQ_SHOW_FLOWSTATS: 
				var url = 'http://' + Config.hostname + ':' + Config.port + '/get_flowstats';
				var param = '';

				for(var key in params) {
					param += key + '=' + params[key] + '&';
				}

				console.log('param: ' + param);
				console.log('url: ' + url + '?' + param);

				new Ajax.Request(url, {
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
