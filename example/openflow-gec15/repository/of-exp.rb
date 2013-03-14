defProperty('wired', 'omf.nicta.node2', "Wired node (endpoint)") # baseline.ndz
defProperty('ap', 'omf.nicta.node3', "Access Point") # ovs-5.4.2-precise.ndz
defProperty('adhoc', 'omf.nicta.node4', "Secondary path node with ad-hoc link to AP") # ovs-5.4.2-precise.ndz
defProperty('wireless', 'omf.nicta.node5', "Wireless node (endpoint)") # baseline.ndz

defGroup('ap', property.ap) do |node|
  # wlan0 is not part of OVS
  # the IP address is the GRE tunnel endpoint
  node.net.w0.mode = "adhoc"
  node.net.w0.type = 'g'
  node.net.w0.channel = "6"
  node.net.w0.essid = "adhoc"
  node.net.w0.ip = "172.16.2.1"
  
  # wlan1 is part of OVS
  node.net.w1.mode = "master"
  node.net.w1.type = 'g'
  node.net.w1.channel = "10"
  node.net.w1.essid = "ap"
end

defGroup('adhoc', property.adhoc) do |node|
  # wlan0 is not part of OVS
  # the IP address is the GRE tunnel endpoint
  node.net.w0.mode = "adhoc"
  node.net.w0.type = 'g'
  node.net.w0.channel = "6"
  node.net.w0.essid = "adhoc"
  node.net.w0.ip = "172.16.2.2"
end

defGroup('wireless', property.wireless) do |node|
  # no OVS on this node
  node.net.w0.mode = "managed"
  node.net.w0.type = 'g'
  node.net.w0.channel = "10"
  node.net.w0.essid = "ap"
  node.net.w0.ip = "172.16.1.4"

  node.addApplication("test:app:otg2", :id => 'flow1') do |app|
    app.setProperty('cbr:rate', 800000)
    app.setProperty('udp:local_host', '172.16.1.4')
    app.setProperty('udp:dst_host', '172.16.1.1')
    app.setProperty('udp:dst_port', 3000)
    app.measure('udp_out', :samples => 1)
  end
  node.addApplication("test:app:otg2", :id => 'flow2') do |app|
    app.setProperty('cbr:rate', 800000)
    app.setProperty('udp:local_host', '172.16.1.4')
    app.setProperty('udp:dst_host', '172.16.1.1')
    app.setProperty('udp:dst_port', 3000)
    app.measure('udp_out', :samples => 1)
  end
end

defGroup('wired', property.wired) do |node|
  node.addApplication("test:app:otr2") do |app|
    app.setProperty('udp:local_host', '172.16.1.1')
    app.setProperty('udp:local_port', 3000)
    app.measure('udp_in', :samples => 1)
  end

  # no OVS on this node
  node.net.e0.ip = "172.16.1.1"
end

onEvent(:ALL_UP) do |event|
  allGroups.exec("sysctl -w net.ipv6.conf.all.disable_ipv6=1")
  
  ovs_init="ovs-vsctl del-br br-int; ovs-vsctl add-br br-int;
ovs-vsctl set-controller br-int tcp:10.0.0.200:6633;
ovs-vsctl set controller br-int connection-mode=out-of-band; ifconfig eth0 0"
  
  group("ap").exec(ovs_init)
  group("adhoc").exec(ovs_init)
  
  group("ap").exec("ovs-vsctl add-port br-int gre1 -- set interface gre1 type=gre options:remote_ip=172.16.2.2")
  group("adhoc").exec("ovs-vsctl add-port br-int gre1 -- set interface gre1 type=gre options:remote_ip=172.16.2.1")
  
  group("ap").exec("ovs-vsctl add-port br-int eth0")
  group("ap").exec("ovs-vsctl add-port br-int wlan1")
  group("adhoc").exec("ovs-vsctl add-port br-int eth0")
  
  group("ap").exec("echo \"<omlc id='AP' exp_id='openflow-demo'><collect url='tcp:10.0.0.200:3004'><stream mp='net_if' name='net_if' samples='1'/></collect><collect url='tcp:10.0.0.200:5000' encoding='text'><stream mp='net_if' name='net_if1' samples='1'/></collect></omlc>\" > /tmp/oml.xml")
  group("ap").exec("nmetrics-oml2 -s 1 -i eth0 -i wlan0 -i wlan1 --oml-config /tmp/oml.xml")

  #group("ap").exec("/root/monitor_ovs_ports.rb --oml-id ap --oml-server tcp:norbit.npc.nicta.com.au:5000")
  #group("adhoc").exec("/root/monitor_ovs_ports.rb --oml-id adhoc --oml-server tcp:norbit.npc.nicta.com.au:5000")

  group("wired").startApplications
  
  info "Start your OpenFlow controller now!"
  sleep 10

  while true
    info "Starting flow 1"
    group("wireless").startApplication('flow1')
    sleep 10
    info "Starting flow 2"
    group("wireless").startApplication('flow2')
    sleep 10
    info "Stopping flow 1. Flow 2 should now re-route over flow 1's path"    
    group("wireless").stopApplication('flow1')
    sleep 20
    info "Starting flow 1. Should use secondary path now."
    group("wireless").startApplication('flow1')
    sleep 20
    info "Stopping flow 2"
    group("wireless").stopApplication('flow2')
    sleep 10
    info "Stopping flow 1"
    group("wireless").stopApplication('flow1')
    sleep 10
    info "Restarting experiment cycle"
  end

end
