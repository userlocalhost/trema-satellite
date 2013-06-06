module Graph
	module Web
		class Config
			DEFAULT_PORTNUM = 9292

			@@port = nil

			def self.port
				@@port
			end

			def self.port= port
				@@port = port
			end
		end
	end
end
