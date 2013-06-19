create table nodes (
	node_id integer primary key autoincrement,
	type tinyint
);

create table switches (
	node_id integer primary key autoincrement,
	dpid bigint unsigned not null
);

create table hosts (
	node_id integer primary key autoincrement,
	neighbor int unsigned,
	dladdr varchar(17),
	nwaddr varchar(15)
);

create table ports (
	dpid bigint unsigned not null,
	portnum smallint unsigned not null,
	node_id int unsigned,
	connection_to bigint unsigned,
	primary key (dpid, portnum)
);

create table entries (
	entry_id integer primary key autoincrement,
	dpid bigint unsigned not null,
	route_id int not null,
	route_index int,
	idle_timeout int unsigned,
	hard_timeout int unsigned,
	created_time timestamp default current_timestamp,
	removed_time timestamp,
	status int unsigned default 0,
	match_wildcards int unsigned,
	match_in_port int unsigned,
	match_dl_src varchar(20),
	match_dl_dst varchar(20),
	match_dl_vlan smallint unsigned,
	match_dl_vlan_pcp tinyint unsigned,
	match_dl_type smallint unsigned,
	match_nw_tos tinyint unsigned,
	match_nw_proto tinyint unsigned,
	match_nw_src varchar(20),
	match_nw_dst varchar(20),
	match_tp_src smallint unsigned,
	match_tp_dst smallint unsigned
);

create table actions (
	entry_id int unsigned not null,
	list_index smallint unsigned not null,
  action_type int,
  outport smallint unsigned,
	primary key (entry_id, list_index)
);

create table flowstats (
	stats_id integer primary key autoincrement,
	entry_id int unsigned not null,
	packet_count bigint unsigned,
	byte_count bigint unsigned,
	time timestamp default current_timestamp
);

create table portstats (
	stats_id integer primary key autoincrement,
	entry_id int unsigned not null,
	dpid bigint unsigned not null,
	portnum smallint unsigned not null,
	node_id int unsigned,
	rx_packets int unsigned,
	tx_packets int unsigned,
	rx_bytes int unsigned,
	tx_bytes int unsigned,
	time timestamp default current_timestamp
);

create table viewcomponents (
	id integer primary key autoincrement,
	type int unsigned not null,
	href varchar(512),
	options varchar(512)
);
