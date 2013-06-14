module Graph
	module Web
		class Config
			@@port = 9292
			@@hostname = 'localhost'

			def self.port
				@@port
			end

			def self.host
				@@hostname
			end

			def self.port= port
				@@port = port
			end

			def self.host= host
				@@hostname = host
			end
		end
	end
end
