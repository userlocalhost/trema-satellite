module Graph
	module Web
		class Component
			@@components = Array.new

			def initialize stanza
				@@components << self

				@stanza = stanza
			end

			def [] param
				@stanza[ param ]
			end

			def self.each &block
				@@components.each do |each|
					block.call each
				end
			end

			protected
			def get_param param_str
				Get.new param_str
			end

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
	end
end
