module DSL
	class TrafficGraph
		attr_reader :title, :dl_src, :dl_dst,
			:is_current_on, :is_maximum_on, :is_prediction_average

		def initialize title
			@title = title
		end

		def range dl_src, dl_dst
			@dl_src = dl_src
			@dl_dst = dl_dst
		end

		def show_type type
			case type
			when Symbol
				check_show_type type
			when Array
				type.each { |x| check_show_type x }
			end
		end

		private
		def check_show_type type
			case type
			when :current
				@is_current_on = true
			when :maximum
				@is_maximum_on = true
			when :prediction_average
				@is_prediction_average_on = false
			else
			end
		end
	end
end
