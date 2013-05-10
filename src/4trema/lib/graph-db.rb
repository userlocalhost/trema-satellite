require "config"

module Graph
	class DB
		# to use initialization
		TABLES = [ 'actions', 'entries', 'portstats', 'flowstats', 
			'hosts', 'nodes', 'ports', 'switches' ]

		def self.get_accessor
			return Mysql.connect(Config::DB_HOST, Config::DB_USER, Config::DB_PASSWD, Config::DB_NAME)
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
