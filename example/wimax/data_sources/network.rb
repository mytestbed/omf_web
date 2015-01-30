



require 'omf_oml/network'
require 'omf_oml/table'

include OMF::OML

class NetworkGenerator

  def self.create_data_source(id, opts)
    nw = OmlNetwork.new 'network'
    nw.node_schema [[:x, :float], [:y, :float], [:capacity, :float]]

    nw.node_schema [[:bs_name, :string], [:latitude, :float], [:longitude, :float], [:elevation, :float], [:frequency, :float], [:bw, :float], [:oid, :string]]
    nw.create_node :r1, bs_name: 'Rutgers 1', latitude:  40.521389, longitude: -74.461111, elevation: 190.0, frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:00:01'
    nw.create_node :r2, bs_name: 'Rutgers 2', latitude:  40.521389, longitude: -74.461111, elevation: 190.0, frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:00:02'
    nw.create_node :r3, bs_name: 'Rutgers 3', latitude:  40.468056, longitude: -74.445556, elevation: 12.0, frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:00:03'
    nw.create_node :g1, bs_name: 'GPO (BBN) 1', latitude: 42.388333, longitude: -71.149167, elevation: 12.0, frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:02:01'
    nw.create_node :g2, bs_name: 'GPO (BBN) 2', latitude: 42.388333, longitude: -71.149167, elevation: 12.0, frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:02:02'
    nw.create_node :p1, bs_name: 'NYU Poly 1', latitude: 40.694722, longitude: -73.985833, elevation: 80.0, frequency: 2585.0, bw: 10.0, oid: '44:51:DB:00:04:01'
    nw.create_node :p2, bs_name: 'NYU Poly 2', latitude: 40.694722, longitude: -73.985833, elevation: 80.0, frequency: 2605.0, bw: 10.0, oid: '44:51:DB:00:04:02'
    nw.create_node :u1, bs_name: 'UCLA 1', latitude: 34.06917, longitude: -118.44333, elevation: 80.0, frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:09:01'
    nw.create_node :u2, bs_name: 'UCLA 2', latitude: 34.07194, longitude: -118.45139, elevation: 80.0, frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:09:02'
    nw.create_node :w1, bs_name: 'Wisconsin 1', latitude: 43.07139, longitude: -89.40667, elevation: 80.0, frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:08:01'
    nw.create_node :w2, bs_name: 'Wisconsin 2', latitude: 43.07528, longitude: -89.40667, elevation: 80.0, frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02'
    nw.create_node :co, bs_name: 'Colorado', latitude: 39.99806, longitude: -105.25194, elevation: 80.0, frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:07:01'
    nw.create_node :cu, bs_name: 'Columbia', latitude: 40.80944, longitude: -73.96000, elevation: 80.0, frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:06:01'
    nw.create_node :um, bs_name: 'UMass', latitude: 42.39361, longitude: -72.53194, elevation: 80.0, frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:05:01'


    nw.link_schema [[:ts, :float], [:load, :float], [:load_wild, :float]]
    links = []
    links << nw.create_link(:lr12, :r1, :r2, :ts => 0, :load => 0.0, :load_wild => 0)
    links << nw.create_link(:lr23, :r2, :r3, :ts => 0, :load => 0.25, :load_wild => 0)
    links << nw.create_link(:lr31, :r3, :r1, :ts => 0, :load => 0.25, :load_wild => 0)

    links << nw.create_link(:lg12, :g1, :g2, :ts => 0, :load => 0.5, :load_wild => 0)

    links << nw.create_link(:lu12, :u1, :u2, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lw12, :w1, :w2, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lrp, :r1, :p1, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lru, :r1, :u1, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lrw, :r1, :w1, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lwco, :w1, :co, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lcou, :co, :u1, :ts => 0, :load => 0.75, :load_wild => 0)


    require 'omf_web'
    OMF::Web.register_datasource nw.to_table(:nodes, :index => :name)
    OMF::Web.register_datasource nw.to_table(:links, :index => :name)

    # Create a table which serves the history of an individual link as a slice
    #
    link_history = nw.to_table(:links, max_size: 1000)
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
              r = rand()
              l[:load] = r * frac + i * frac
              l[:load_wild] = r
            end
          end
        end
      rescue Exception => ex
        puts ex
        puts ex.backtrace.join("\n")
      end
    end
  end
end

