module DSL
	class Parser
		def parse conf_file
			Sytax.new.instance_eval IO.read( conf_file )
		end
	end
end
