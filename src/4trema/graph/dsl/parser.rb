require 'graph/dsl/syntax'

module Graph
	module DSL
		class Parser
			def self.parse conf_file
				Graph::DSL::Syntax.new.instance_eval IO.read( conf_file )
			end
		end
	end
end
