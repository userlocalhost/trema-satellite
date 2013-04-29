require 'relation'
require 'traffic'
require 'route'
require 'entry'

module DSL
	class Syntax
		def relation title=nil, &block
			stanza = RelationGraph.new title
			stanza.instance_eval( &block )
		end

		def traffic title=nil, &block
			stanza = TrafficGraph.new title
			stanza.instance_eval( &block )
		end

		def route title=nil, &block
			stanza = RouteGraph.new title
			stanza.instance_eval( &block )
		end

		def entry title=nil, &block
			stanza = EntryGraph.new title
			stanza.instance_eval( &block )
		end
	end
end
