



require 'omf-oml/network'
require 'omf-oml/table'

include OMF::OML
  
nw = OmlNetwork.new 'static_network'
nw.node_schema [[:x, :float], [:y, :float], [:capacity, :float]]
nw.create_node :n0, :x => 0.2, :y => 0.2, :capacity =>  0.3
nw.create_node :n1, :x => 0.8, :y => 0.2, :capacity =>  0.5
nw.create_node :n2, :x => 0.5, :y => 0.5, :capacity =>  0.8
nw.create_node :n3, :x => 0.8, :y => 0.8, :capacity =>  0.8
nw.create_node :n4, :x => 0.2, :y => 0.8, :capacity =>  0.8

nw.link_schema [[:ts, :float], [:load, :float]]
links = []
links << nw.create_link(:l02, :n0, :n2, :ts => 0, :load => 0.0)
links << nw.create_link(:l12, :n1, :n2, :ts => 0, :load => 0.25)
links << nw.create_link(:l23, :n2, :n3, :ts => 0, :load => 0.5)
links << nw.create_link(:l24, :n2, :n4, :ts => 0, :load => 0.75)

require 'omf_web'
OMF::Web.register_datasource nw, :index => :id

# Create a table which serves the history of an individual link as a slice
#
link_history = nw.to_table(:links)
OMF::Web.register_datasource link_history, :name => 'link_history'

# Change load
Thread.new do
  begin
    ts = 0
    loop do
      sleep 1
      ts = ts + 1
      frac = 1.0 / links.length
      nw.transaction do
        links.each_with_index do |l, i| 
          l[:ts] = ts
          l[:load] = rand() * frac + i * frac 
        end
      end
    end
  rescue Exception => ex
    puts ex
    puts ex.backtrace.join("\n")
  end
end


