require 'rubygems'
require 'rack'
require 'erb'

require 'lib/graph-db'

class Tmp01
	def call env
		template_path = 'static/sample.erb'

		@portstats = Graph::DB.query 'select rx_packets, tx_packets, rx_bytes, tx_bytes, time from portstats where dpid = 1 and portnum = 1 limit 50'

		[200, {"Content-Type" => 'text/html'}, [ convert_erb2html( template_path ) ]]
	end

	private
	def convert_erb2html path
		tmp_path = "/tmp/hoge"

		erb = ERB.new( File.read( path ) )
		File.open(tmp_path, 'w') do |file|
			file.write erb.result(binding)
		end

		return File.read(tmp_path)
	end
end
