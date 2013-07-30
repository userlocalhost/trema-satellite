require 'rubygems'
require 'sqlite3'

module Graph
	class DB
		INIT_SQL_PATH = File.dirname( __FILE__ ) + '/sql/init_sqlite3.sql'
		DB_PATH = File.dirname( __FILE__ ) + "/../tmp/graph.db"

		# to use initialization
		TABLES = [ 'actions', 'entries', 'portstats', 'flowstats', 
			'hosts', 'nodes', 'ports', 'switches', 'viewcomponents' ]

		def initialize
			if ! FileTest.exist? File.dirname( DB_PATH ) then
				FileUtils.mkdir_p File.dirname( DB_PATH )
			end

			db_exists = FileTest.exist? DB_PATH

			@db = SQLite3::Database.new DB_PATH
			if ! db_exists then
				@db.execute_batch File.read( INIT_SQL_PATH )
			end
		end

		def query sql
			ret = nil

			if sql =~ /^insert into / then
				@db.execute( sql )
				ret = @db.last_insert_row_id
			elsif sql =~ /select (.*) from/
				key = $1.delete(' ').split(',').map { |x| x.to_sym }
	
				ret = Array.new
				@db.execute( sql ).each do |each|
					ret << Hash[ *key.zip( each ).flatten ]
				end
			else
				@db.execute sql
			end

			@db.close

			ret
		end

		def self.clear
			if FileTest.exist? DB_PATH
				File.delete DB_PATH
			end
		end
	end
end
