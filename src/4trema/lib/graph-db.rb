module Graph
	class DB
		HOST = 'localhost'
		USER = 'root'
		PASS = 'airone'
		NAME = 'graph'

		# to use initialization
		TABLES = [ 'actions', 'entries', 'portstats', 'flowstats', 
			'hosts', 'nodes', 'ports', 'switches' ]

		def self.get_accessor
			return Mysql.connect(HOST, USER, PASS, NAME)
		end

		def self.clear
			client = get_accessor
			TABLES.each do |each|
				client.prepare( "delete from #{each}" ).execute
			end
			client.close
		end
	end
end
