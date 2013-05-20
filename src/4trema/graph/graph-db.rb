require "config"
require "mysql"

module Graph
	class DB
		# to use initialization
		TABLES = [ 'actions', 'entries', 'portstats', 'flowstats', 
			'hosts', 'nodes', 'ports', 'switches' ]

		def self.get_accessor
			return Mysql.connect(Config::DB_HOST, Config::DB_USER, Config::DB_PASSWD, Config::DB_NAME)
		end

		def self.query sql
			accr = get_accessor

			if sql =~ /^insert into / then
        stmt = client.prepare(sql).execute

				ret = stmt.insert_id
			elsif sql =~ /select (.*) from/
				key = $1.delete(' ').split(',').map { |x| x.to_sym }

				ret = Array.new
				accr.query( sql ).each do |each|
					ret << Hash[*(key.zip(each)).flatten]
				end
			else
				ret = accr.query sql 
			end

			accr.close

			return ret
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
