module DSL
	class RelationGraph
		attr_reader :title, :is_host_on, :is_port_on
		def initialize title
			@title = title
			@is_host_on = false
			@is_port_on = false
		end

		def show_host
			@is_host_on = true
		end

		def show_port
			@is_port_on = true
		end
	end
end
