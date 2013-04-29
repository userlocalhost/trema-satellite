module Graph
	class DB
		HOST = 'localhost'
		USER = 'root'
		PASS = 'airone'
		NAME = 'graph'

		# to use initialization
		TABLES = ['actions', 'entries', 'flowstats', 'hosts', 'nodes', 'ports', 'switches']

		def self.get_accessor
			return Mysql.connect(HOST, USER, PASS, NAME)
		end

		def self.clear
			TABLES.each do |each|
				get_accessor.prepare( "delete from #{each}" ).execute
			end
		end
	end
end
