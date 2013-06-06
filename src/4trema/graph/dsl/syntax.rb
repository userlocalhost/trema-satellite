require 'graph/dsl/port'
require 'graph/dsl/topology'
require 'graph/dsl/porttraffic'

require 'graph/web/controller/topology'
require 'graph/web/controller/portstats'

require 'graph/web/config'

module Graph
	module DSL
		class Syntax
			def topology title=nil, &block
				stanza = Topology.new title
				stanza.instance_eval( &block )
	
				Graph::Web::Controller::Topology.new stanza
			end
	
			def porttraffic title=nil, &block
				stanza = PortTraffic.new title
				stanza.instance_eval( &block )
	
				Graph::Web::Controller::PortStats.new stanza
			end

			def port portnum
				Graph::Web::Config.port = portnum.to_i
			end
		end
	end
end
