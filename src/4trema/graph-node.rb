require 'graph-db'

module Graph
	class NodeType
		TYPE_PORT = 1 << 0
		TYPE_HOST = 1 << 1
		TYPE_DATAPATH = 1 << 2

		def self.port
			TYPE_PORT
		end

		def self.host
			TYPE_HOST
		end

		def self.datapath
			TYPE_DATAPATH
		end
	end

	class Port
		DB_HOST = 'localhost'
		DB_USER = 'root'
		DB_PASS = 'airone'
		DB_NAME = 'graph'

		attr_accessor :rx_packets, :tx_packets, :rx_bytes, :tx_bytes
		attr_reader :dpid, :portnum, :neighbor, :node_id

		@@ports = []

		def initialize dpid, portnum
			@dpid = dpid
			@portnum = portnum
			@neighbor = 0			# this member indicates the node-id
			@rx_packets = 0
			@tx_packets = 0
			@rx_bytes = 0
			@tx_bytes = 0

			@node_id = ( isin_db? ) ? get_nodeid : Graph::Port.add_node
		end

		# this will change dpid to node_id
		def set_neighbor node_id
			@neighbor = node_id

			store_db
		end

		def isin_db?
			client = Graph::DB.get_accessor

			query = client.query "select * from ports where dpid = #{@dpid} and portnum = #{@portnum}"

			return (query.num_rows > 0) ? true : false
		end

		def get_nodeid
			query = Graph::DB.get_accessor.query("select node_id from ports where dpid = #{@dpid} and portnum = #{@portnum}")

			return (query != nil) ? query.fetch_row : nil
		end

		def store_db
			sql = ""
			client = Graph::DB.get_accessor

			if isin_db? then
				sql = "update ports set
								connection_to = #{@neighbor},
								rx_packets = #{@rx_packets},
								tx_packets = #{@tx_packets},
								rx_bytes = #{@rx_bytes},
								tx_bytes = #{@tx_bytes} where dpid = #{@dpid} and portnum = #{@portnum}"
			else
				sql = "insert into ports 
								(dpid, node_id, portnum, connection_to, rx_packets, tx_packets, rx_bytes, tx_bytes) values
								(#{@dpid}, #{@node_id}, #{@portnum}, #{@neighbor}, #{@rx_packets}, #{@tx_packets}, #{@rx_bytes}, #{@tx_bytes})"
			end

			if sql.length > 0 then
				stmt = client.prepare sql

				stmt.execute
			end
		end
		
		def self.dump
			print "[Port] ==== (dump) ====\n"
			@@ports.each do |each|
				print "[Port] (dump) [#{each.dpid}:#{each.portnum}] neighbor: #{each.neighbor}\n"
				print "[Port] (dump) [#{each.dpid}:#{each.portnum}] rx_packets: #{each.rx_packets}\n"
				print "[Port] (dump) [#{each.dpid}:#{each.portnum}] tx_packets: #{each.tx_packets}\n"
				print "[Port] (dump) [#{each.dpid}:#{each.portnum}] rx_bytes: #{each.rx_bytes}\n"
				print "[Port] (dump) [#{each.dpid}:#{each.portnum}] tx_bytes: #{each.tx_bytes}\n"
			end
			print "[Port] ================\n"
		end

		def self.get_from_node_id node_id
			return nil if node_id <= 0

			@@ports.find { |x| x.node_id == node_id }
		end

		def self.get dpid, portnum
			port = _get dpid, portnum
			if ! port || (! port.instance_of? self) then
				port = self.new dpid, portnum

				@@ports << port
			end

			return port
		end

		private
		def self._get dpid, portnum
			@@ports.find { |x| (x.dpid == dpid) && (x.portnum == portnum) }
		end

		# This routine returns node_id that
		def self.add_node
			Graph::DB.get_accessor.prepare("insert into nodes (type) values (#{NodeType.port})").execute.insert_id
		end
	end

	class Host
		attr_reader :mac, :ip, :neighbor, :node_id
		
		@@hosts = []

		def initialize mac, ip, neighbor
			@neighbor = neighbor
			@mac = mac
			@ip = ip

			@node_id = ( isin_db? ) ? get_nodeid : Graph::Host.add_node
		end

		def set_neighbor nodeid
			@neighbor = nodeid

			store_db
		end

		def regist
			@@hosts << self
		end

		def store_db
			if ! isin_db? then
				client = Graph::DB.get_accessor

				sql = "insert into hosts (node_id, neighbor, dladdr, nwaddr) values (#{@node_id}, #{@neighbor}, '#{@mac}', '#{@ip}')"

				client.prepare( sql ).execute
			end
		end

		def isin_db?
			client = Graph::DB.get_accessor
			sql = "select * from hosts where dladdr = '#{@mac}' and nwaddr = '#{@ip}'"

			query = client.query sql

			return (query.num_rows > 0) ? true : false
		end

		def get_nodeid
			query = Graph::DB.get_accessor.query("select node_id from hosts where dladdr = '#{@mac}' and nwaddr = '#{@ip}'")

			return (query != nil) ? query.fetch_row : nil
		end

		def self.get_from_node_id node_id
			@@hosts.find { |x| x.node_id == node_id }
		end

		def self.isin? dl_addr
			@@hosts.any? { |x| (x.mac == dl_addr) }
		end

		def self.isin_node_id? node_id
			@@hosts.any? { |x| (x.node_id == node_id) }
		end

		def self.add_node
			insert_id = Graph::DB.get_accessor.prepare("insert into nodes (type) values (#{NodeType.host})").execute.insert_id

			return insert_id
		end
	end
end
