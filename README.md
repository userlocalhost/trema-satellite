Wellcome to Trema-Satellite (T-Sat)
==================================

Trema Satellite (T-Sat) is a library to visualize OpenFlow Network automatically.

In the past, user has used some kind of tools to see the health of the network 
( e.g. some statistics information ) and behavior of the controller, 
in such a way as to look it at with a magnifying glass.

T-Sat takes a view of OpenFlow network situation, comprehensively and integratively.
And you can customize it to see what you want to see, with a simple configuration like following.

```ruby
port 9393
host 'vmtrema'

topology('Topology') {
  href 'topology'
}

porttraffic('Traffic-Trends') {
  href '/porttraffic'
}
```

By this configuration, you can obtain the following views.

![Topology-Graph](http://userlocalhost2000.github.io/trema-satellite/images/scr_topology.png)
![Traffic-Graph](http://userlocalhost2000.github.io/trema-satellite/images/scr_traffic.png)
![Traffic-Views-Graph](http://userlocalhost2000.github.io/trema-satellite/images/scr_traffic_views.png)


Why T-Sat needs
---------------

OpenFlow enables us to control fabric-network more flexible. And we can know the behavior using some CLI tools which trema and switch prepared.

But these tools are not always adequate for our needs. There are times that we want to know rough data than accurate statistics.

T-Sat helps us to grasp the outline of network situation.


Getting Started
---------------

### Bebore Building

* Install Trema

T-Sat is a library of Trema application. In other words, 
this works as an application of Trema. So you have to install <a href="http://trema.github.io/trema">Trema</a>.

* Install Mongrel (web server)

And T-Sat represents web-viewer that works in conjunction with Trema. 
It is therefore T-Sat uses the <a href='http://rubygems.org/gems/mongrel'>mongrel</a> which is a small HTTP library and web server.
You can install mongrel with the following command

    $ gem install mongrel

* Creating Database

** This processing will be dropped in near future. **

T-Sat stores some statistics data in the database using MySQL.
Now, you have to create a database using 'sql/init.sql' like following.

    $ mysql -uuser -ppassword < sql/init.sql

### Using T-Sat

The way to use T-Sat is very simple. 
You only have to change name of the Controller class to 
'TremaSattelite' and load T-Sat library from your controller as follows.

```ruby
class TremaSattelite
  ...
end

require 'graph'
```

### Starting Trema-Sattelite

To start T-Sat, you have to use 'start_trema_satellite' command which is in the top directory. The command-line options are almost same of Trema. A new option is '-f' that specifies view-configuration. For more detail of this, please see the usage by '-h' option. Following is an example of the way to use this command.

    $ ./start_trema_satellite -c examples/trema_conf/l2switch_env.conf -f examples/graph_conf/graph.conf examples/learning-switch.rb

To see the pictures that T-Sat generate, please access from here.

    http://hostname:9393/porttraffic


Configuration
-------------

You can use T-Sat without any configuration. But to write 
a configure file for T-Sat, which is named 'tsat.conf', you can
customize output-views.

### how to use

One of an example of tsat.conf is following.

```ruby
#tsat.conf
port 8080
host 'tsat-test'

topology('Topology Graph') {
  href '/topology'
  option 'heatmap'
}

porttraffic('Traffic-Trends Graph') {
  href '/traffic'
}
```

Once execute Trema with 'start_trema_satellite' command, you can see topology-graph and port-stats graph.

    # for topology graph
    http://tsat-test:8080/topology

    # for port-stats graph
    http://tsat-test:8080/traffic
