require 'rubygems'
require 'omf_oml/endpoint'
require 'omf_oml/table'
require 'omf_common/lobject'

OMLPORT=5000
# threshold for transmitted bytes/s on AP's eth0 interface
# when exceeded, route new flows through secondary path
PRIMARY_THRESHOLD=100000

class OFDemo < Controller
  
  add_timer_event :check_flows, 3, :periodic
  
  def start
    @switches = {"ap" => 0x32d0cfcb0, "adhoc" => 0x32d081a16, "of1" => 0x2320ca156c}
    @ports = Hash.new
    @detour=false
    @lastflow=0

    OMF::Common::Loggable.init_log File.basename($0).split('.')[0]
    ep = OMF::OML::OmlEndpoint.new(OMLPORT, '0.0.0.0')
    ep.on_new_stream() do |name, stream|
      #puts "New stream: #{name}::#{stream}"
      txcount=0
      first=true
      stream.on_new_tuple() do |t|
        tx=t.to_a[11].to_i
        if first
          first=false
          next
        end
        #puts "New tuple: #{t.to_a.inspect}"
        txc=tx-txcount
        txcount=tx
        @detour = txc > PRIMARY_THRESHOLD
        puts "AP eth0 reports #{txc} bytes/s, saturated: #{@detour}"
      end
    end
    ep.run(true)
  end
  
  def switch_ready dpid
    puts "Switch #{@switches.index(dpid)} (#{dpid.to_hex}) has signed in"
    send_message dpid, FeaturesRequest.new
  end

  def features_reply dpid, message
    @ports[dpid] = Hash.new
    # read port name and number from the features_reply
    message.ports.each do | p |
      #puts "#{@switches.index(d)} : #{p.name} = #{p.number}"
      @ports[dpid][p.name] = p.number
    end
  end
  
  def packet_in dpid, message
    # drop it if we don't now the switch or its ports (yet)
    return if @switches.index(dpid).nil? or @ports[dpid].nil?    
    
    arp_error="Unidentified ARP traffic. You may have started the controller too early, please restart it."
    
    # handle ARP traffic manually to avoid packet storm in our circular topology
    if message.arp?
      if @switches.index(dpid)=="ap"
        if message.in_port==@ports[dpid]['wlan1']
          packet_out dpid, message, @ports[dpid]['eth0']
        elsif message.in_port==@ports[dpid]['eth0']
          packet_out dpid, message, @ports[dpid]['wlan1']
        else
          puts arp_error
        end
      elsif @switches.index(dpid)=="of1"
        if message.in_port==2
          packet_out dpid, message, 3
        elsif message.in_port==3
          packet_out dpid, message, 2
        else
          puts arp_error
        end
      end
      return
    end
    
    # from now on we are only interested on IPv4 packets arriving on AP over wlan1
    return if !message.ipv4? or @switches.index(dpid)!="ap" or message.in_port!=@ports[dpid]['wlan1']

    # slow down adding of flows
    # t=Time.now.to_i
    # if t-@lastflow > 2
    #   @lastflow=t
    # else
    #   return
    # end
    
    # add the flow on AP after adding all the others to avoid loss of inital packets
    if @detour
      puts "Adding flow over secondary path"
      # broken due to trema bug
      #flow_mod @switches["adhoc"], message, @ports[dpid]['eth0']
      #flow_mod @switches["of1"], message, 2
      flow_mod dpid, message, @ports[dpid]['gre1']
    else
      puts "Adding flow over primary path"
      # broken due to trema bug
      #flow_mod @switches["of1"], message, 2
      flow_mod dpid, message, @ports[dpid]['eth0']
    end
    
  end
  
  # periodically check if the throughput on primary path is below threshold
  # if yes, remove flows that currently use secondary path
  def check_flows
    return if @ports[@switches["ap"]].nil?
    if !@detour
      puts "Deleting flows on switch #{@switches["ap"].to_hex} with out_port #{@ports[@switches["ap"]]['gre1']}"
      send_flow_mod_delete(
        @switches["ap"].to_i,
        :actions => ActionOutput.new( :port => @ports[@switches["ap"]]['gre1'] )
      )
    end
  end
  
  ##############################################################################
  private
  ##############################################################################

  def flow_mod datapath_id, message, port_no
    #p Match.from( message, [ :dl_type, :nw_proto ] )
    send_flow_mod_add(
      datapath_id,
      :match => Match.from( message ),
      :actions => ActionOutput.new( :port => port_no ),
      :idle_timeout => 2
    )
  end

  def packet_out datapath_id, message, port_no
    send_packet_out(
      datapath_id,
      :packet_in => message,
      :actions => ActionOutput.new( :port => port_no )
    )
  end
  
end

