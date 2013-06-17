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

![Traffic-Graph](http://userlocalhost2000.github.io/trema-satellite/images/scr_traffic.png)
![Topology-Graph](http://userlocalhost2000.github.io/trema-satellite/images/scr_topology.png)


Why T-Sat needs
---------------

OpenFlow enables us to control fabric-network more flexible. And we can know the behavior using some CLI tools which trema and switch prepared.

But these tools are not always adequate for our needs. There are times that we want to know rough data than accurate statistics.

T-Sat helps us to grasp the outline of network situation.


Getting Started
---------------

### Bebore Building

1. Install Trema

T-Sat is a library of Trema application. In other words, 
this works as an application of Trema. So you have to install <a href="http://trema.github.io/trema">Trema</a>.

2. Install Mongrel (web server)

And T-Sat represents web-viewer that works in conjunction with Trema. 
It is therefore T-Sat uses the <a href='http://rubygems.org/gems/mongrel'>mongrel</a> which is a small HTTP library and web server.
You can install mongrel with the following command

    $ gem install mongrel

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

To see the pictures that T-Sat generate, please access from here.

    http://hostname:9292/


Configuration
-------------

You can use T-Sat without any configuration. But to write 
a configure file for T-Sat, which is named 'tsat.conf', you can
customize output-views.

### how to use

You can load the configuration file that you wrote 
using load_config method from 'start' event-handler as follows.

```ruby
# Trema Controller Application File
class TremaSattelite
  ...
  def start
    load_config "tsat.conf"
  end
end
```

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

Once execute Trema with 'trema run', you can see topology-graph and port-stats graph.

    # for topology graph
    http://tsat-test:8080/topology

    # for port-stats graph
    http://tsat-test:8080/traffic
