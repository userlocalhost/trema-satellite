Server = function() {
	const DEFAULT_SERVER_URL = "http://vmtrema:3000/graph";

	return {
		base_url : function() {
			return DEFAULT_SERVER_URL;
		},
	};
}();
