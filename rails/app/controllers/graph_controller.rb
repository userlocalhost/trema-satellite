require 'json'

class GraphController < ApplicationController
	SCREEN_WIDTH = 500
	SCREEN_HEIGHT = 400

	OFPAT_OUTPUT = 0

	def index
		@width = SCREEN_WIDTH
		@height = SCREEN_HEIGHT

		@ports = Port.find(:all, :conditions => ["connection_to > 0"])
		@hosts = Host.all
		actions = Action.all

		@switch_positions = get_switch_positions @ports, SCREEN_WIDTH, SCREEN_HEIGHT

		@routes = []

		routes = Entry.find_by_sql("select distinct route_id from entries where route_id > 0")
		routes.each do |each|
			route = Entry.find(:all, :conditions => ["route_id = #{each.route_id}"], :order => 'route_index')
			routepath = []

			route.each do |entry|
				port = @ports.find { |x| (x.dpid == entry.dpid) && (x.portnum == entry.match_in_port) }

				routepath.push port.connection_to
				routepath.push port.node_id
			end

			action = actions.find { |x| x.entry_id == route.last.entry_id }
			port = @ports.find { |x| (x.dpid == route.last.dpid) && (x.portnum == action.outport) }

			routepath.push port.node_id
			routepath.push port.connection_to
			
			#routes.push route.first[]
			entries = route.map{|x| {'entry_id' => x.entry_id, 'dpid' => x.dpid}}.to_json

			@routes.push({"route_id" => each.route_id, "entries" => entries, "path" => routepath.to_json})
		end
	end

	def get_switch_info
		render :json => Port.find(:all, :conditions => ["dpid = #{params[:id]}"])
	end

	def get_route_info
		id_param = params[:entry_id]

		if ! id_param.split(':').all? {|x| /^[0-9:]+$/ =~ x}
			return render :json => [], :status => :internal_server_error
		end

		entries = []
		id_param.split(':').map {|x| x.to_i}.each do |entry_id|
			entry = Entry.find_by_entry_id(entry_id)
			actions = Action.find(:all, :conditions => ["entry_id = #{entry_id}"], :order => 'list_index')

			actions.each do |each|
				if each['action_type'] == OFPAT_OUTPUT
					port_info = Port.find_by_sql( "select connection_to from ports where dpid = #{entry['dpid']} and portnum = #{each['outport']}" ).first

					each['connection_to'] = port_info['connection_to']
					break
				end
			end

			entries.push({:entry => entry, :actions => actions})
		end

		render :json => entries
	end

	def get_flow_stats
		render :json => Flowstat.all
	end

	def entry
		#@entries = Entry.all :order => 'dpid asc'
		@entries = Entry.find :all, :order => 'dpid asc'

		@entry = Entry.find_by_entry_id 20
	end

	def get_entries
		json = Array.new

		Entry.find(:all, :conditions => ["route_id > 0"]).each do |each|
			entry = each.attributes

			entry['actions'] = Array.new
			Action.find(:all, :conditions => ["entry_id = #{each.entry_id}"], :order => 'list_index').map do |action|
				entry['actions'].push action
			end

			json.push entry
		end

		render :json => json
	end

	private
	def get_grid_wh num
		width = 1
		height = 1
	
		while ((width * height) < num)
			p "(w,h) = (#{width}, #{height})"
	
			if (width > height) then
				height += 1
			else
				width += 1
			end
		end
	
		return [width, height]
	end

	def get_switch_positions ports, width, height
		switches = ports.map{ |s| s.dpid }.uniq

		(x_count, y_count) = get_grid_wh switches.length

		block_width = (width / x_count)
		block_height = (height / y_count)

		switch_positions = []
		switches.each_with_index do |dpid, i|
			x_index = i % x_count
			y_index = i / x_count

			switch_positions.push({
				'dpid' => dpid,
				'x' => (x_index * block_width) + rand(block_width),
				'y' => (y_index * block_height) + rand(block_height),
			})
		end

		return switch_positions
	end
end
