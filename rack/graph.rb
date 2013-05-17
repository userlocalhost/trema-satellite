require 'rubygems'
require 'rack'

require 'graph-db'

class GraphUI
	def call env
		p env

		case env['REQUEST_PATH']
		when '/'
			[200, {"Content-Type" => 'text/plain'}, ["Hello Rack (root)"]]
		when '/hoge'
			[200, {"Content-Type" => 'text/plain'}, ["Hello Rack (hoge)"]]
		else
			[200, {"Content-Type" => 'text/plain'}, ["Hello Rack (other)"]]
		end
	end
end
