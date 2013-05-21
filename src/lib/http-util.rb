module HttpUtil
	class Get
		attr_reader :path

		def initialize param_str
			@params = param_str.split( '&' ).map do |each| 
				kv = each.split '='
			
				{ :key => kv[0], :value => kv[1] }
			end
		end

		# this method returns GET-parameter value
		def get param_key
			@params.find { |x| x[:key] == param_key } if @params != nil
		end
	end
end
