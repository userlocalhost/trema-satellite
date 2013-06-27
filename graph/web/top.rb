require 'time'
require 'json'
require 'erb'

require 'graph/graph-db'

module Graph
	module Web
		class Top
			STATIC_DIR = 'graph/web/static/'
		
			def call env
				ret = {:body => '', :status => 404, :header => {"Content-Type" => "text/plain"}}
		
				case env['REQUEST_PATH']
				when /^\/img\/.*/
					ret = ret_file( env )
					ret[:header] = {"Content-Type" => "image/jpeg"}
				when /^\/css\/.*/
					ret = ret_file( env )
					ret[:header] = {"Content-Type" => "text/css"}
				when /^\/js\/.*/
					ret = ret_file( env )
					ret[:header] = {"Content-Type" => "text/javascript"}
				else
					path = env['REQUEST_PATH'].gsub /\/+/, '/'

					Component.each do |each|
						if path.index( each[ :href ] ) == 0 then
							ret = each.call env

							break
						end
					end
				end

				return ret[:status], ret[:header], ret[:body]
			end
		
			private
			def ret_file env
				path = STATIC_DIR + env['REQUEST_PATH'].slice(1, env['REQUEST_PATH'].length)
				status = 200
				body = ''
		
				if File.exist? path
					body = File.read path
				else
					status = 404
				end
		
				return {:body => body, :status => status}
			end
		end
	end
end
