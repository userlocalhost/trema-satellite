module Graph
	module DSL
		class ViewPrimitive
			attr_reader :title
	
			def initialize title
				@title = title
				@options = Array.new
			end
	
			def href path
				path.gsub! /\/+/, '/'

				@href = ( path.index('/') == 0 ) ? path : "/#{path}"
			end
	
			def option value
				@options << value
			end

			def [] attr
				instance_variable_get "@#{ attr }"
			end
		end
	end
end
