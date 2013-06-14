require 'rubygems'
require 'rack'

require 'graph/web/config'
require 'graph/web/top'

module Graph
	module Web
		class Runner
			def self.run
				port = Graph::Web::Config.port

				Process.fork do
					Rack::Handler::Mongrel.run Graph::Web::Top.new, :Port => port
				end
			end
		end
	end
end
