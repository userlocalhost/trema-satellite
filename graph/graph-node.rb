require 'graph/graph-db'

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

		attr_reader :dpid, :portnum, :neighbor, :node_id

		@@ports = []

		def initialize dpid, portnum
			@dpid = dpid
			@portnum = portnum
			@neighbor = 0			# this member indicates the node-id

			@prev_rx_packets = 0
			@prev_tx_packets = 0
			@prev_rx_bytes = 0
			@prev_tx_bytes = 0

			@node_id = ( isin_db? ) ? get_nodeid : Graph::Port.add_node
		end

		# this will change dpid to node_id
		def set_neighbor node_id
			@neighbor = node_id

			store_db
		end

		def isin_db?
			ret = Graph::DB.new.query "select dpid from ports where dpid = #{@dpid} and portnum = #{@portnum}"

			return ( ret.length > 0 ) ? true : false
		end

		def get_nodeid
			ret = Graph::DB.new.query "select node_id from ports where dpid = #{@dpid} and portnum = #{@portnum}"

			return ( ret.length > 0 ) ? ret[0][:node_id] : nil
		end

		def store_db_stats rx_p, tx_p, rx_b, tx_b
			rx_pd = rx_p - @prev_rx_packets
			tx_pd = tx_p - @prev_tx_packets
			rx_bd = rx_b - @prev_rx_bytes
			tx_bd = tx_b - @prev_tx_bytes

			@prev_rx_packets = rx_p
			@prev_tx_packets = tx_p
			@prev_rx_bytes = rx_b
			@prev_tx_bytes = tx_b

			Graph::DB.new.query "insert into portstats
					(dpid, portnum, node_id, rx_packets, tx_packets, rx_bytes, tx_bytes) values
					(#{@dpid}, #{@portnum}, #{@node_id}, #{rx_pd}, #{tx_pd}, #{rx_bd}, #{tx_bd})"
		end

		def store_db
			if isin_db? then
				Graph::DB.new.query "update ports set connection_to = #{@neighbor} where dpid = #{@dpid} and portnum = #{@portnum}"
			else
				Graph::DB.new.query "insert into ports 
								(dpid, node_id, portnum, connection_to) values
								(#{@dpid}, #{@node_id}, #{@portnum}, #{@neighbor})"
			end
		end

		def save
			index = @@ports.index self

			@@ports.delete_at index
			@@ports << self
		end
		
		def self.dump
			print "[Port] ==== (dump) ====\n"
			@@ports.each do |each|
				print "[Port] (dump) [#{each.dpid}:#{each.portnum}] neighbor: #{each.neighbor}\n"
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
			Graph::DB.new.query "insert into nodes (type) values (#{NodeType.port})"
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
				Graph::DB.new.query "insert into hosts (node_id, neighbor, dladdr, nwaddr) values (#{@node_id}, #{@neighbor}, '#{@mac}', '#{@ip}')"
			end
		end

		def isin_db?
			ret = Graph::DB.new.query "select * from hosts where dladdr = '#{@mac}' and nwaddr = '#{@ip}'"

			return (ret.length > 0) ? true : false
		end

		def get_nodeid
			ret = Graph::DB.new.query "select node_id from hosts where dladdr = '#{@mac}' and nwaddr = '#{@ip}'"

			return ( ret.length > 0 ) ? ret[0][:node_id] : nil
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
			Graph::DB.new.query "insert into nodes (type) values (#{NodeType.host})"
		end
	end
end
