require 'graph/dsl/parser'

require 'graph/web/component'
require 'graph/web/runner'

if ! File.exists? ARGV[0] || ARGV[0] == nil then
	p "Usage: web-runner.rb <tsat-config>"

	exit 1
end

Graph::DSL::Parser.parse ARGV[0]

pid = Graph::Web::Runner.run

Signal.trap :INT do
	Signal.trap :INT, {}

	Process.kill :KILL, pid
end

Signal.trap :TERM do
	Signal.trap :TERM, {}

	Process.kill :KILL, pid
end

Process.waitpid pid
