



require 'omf_oml/network'
require 'omf_oml/table'

include OMF::OML

class NetworkGenerator

  def self.create_data_source(id, opts)
    nw = OmlNetwork.new 'network'
    nw.node_schema [[:ts, :float], [:bs_name, :string], [:latitude, :float], [:longitude, :float], [:elevation, :float],
                    [:frequency, :float], [:bw, :float], [:oid, :string], [:zoom_viz, :string],
                    [:load, :float], [:load_wild, :float]]
    nodes = []
    nodes << nw.create_node(:r1, ts: 0, ts: 0, bs_name: 'Rutgers 1', latitude:  40.521389, longitude: -74.461111, elevation: 190.0,
                   frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:00:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:r2, ts: 0, bs_name: 'Rutgers 2', latitude:  40.521389, longitude: -74.461111, elevation: 190.0,
                   frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:00:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:r3, ts: 0, bs_name: 'Rutgers 3', latitude:  40.468056, longitude: -74.445556, elevation: 12.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:00:03', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:g1, ts: 0, bs_name: 'GPO (BBN) 1', latitude: 42.388333, longitude: -71.149167, elevation: 12.0,
                   frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:02:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:g2, ts: 0, bs_name: 'GPO (BBN) 2', latitude: 42.388333, longitude: -71.149167, elevation: 12.0,
                   frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:02:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:p1, ts: 0, bs_name: 'NYU Poly 1', latitude: 40.694722, longitude: -73.985833, elevation: 80.0,
                   frequency: 2585.0, bw: 10.0, oid: '44:51:DB:00:04:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:p2, ts: 0, bs_name: 'NYU Poly 2', latitude: 40.694722, longitude: -73.985833, elevation: 80.0,
                   frequency: 2605.0, bw: 10.0, oid: '44:51:DB:00:04:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:u1, ts: 0, bs_name: 'UCLA 1', latitude: 34.06917, longitude: -118.44333, elevation: 80.0,
                   frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:09:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:u2, ts: 0, bs_name: 'UCLA 2', latitude: 34.07194, longitude: -118.45139, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:09:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w1, ts: 0, bs_name: 'Wisconsin 1', latitude: 43.07139, longitude: -89.40667, elevation: 80.0,
                   frequency: 2590.0, bw: 10.0, oid: '44:51:DB:00:08:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w2, ts: 0, bs_name: 'Wisconsin 2', latitude: 99999, longitude: -89.40667, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w3, ts: 0, bs_name: 'Wisconsin 3', latitude: 99999, longitude: 99999, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w4, ts: 0, bs_name: 'Wisconsin 4', latitude: 99999, longitude: 99999, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w5, ts: 0, bs_name: 'Wisconsin 5', latitude: 99999, longitude: 99999, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w6, ts: 0, bs_name: 'Wisconsin 6', latitude: 99999, longitude: 99999, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:w7, ts: 0, bs_name: 'Wisconsin 7', latitude: 99999, longitude: 99999, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:08:02', zoom_viz: 'secondary', load: 0, load_wild: 0)
    nodes << nw.create_node(:co, ts: 0, bs_name: 'Colorado', latitude: 39.99806, longitude: -105.25194, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:07:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:cu, ts: 0, bs_name: 'Columbia', latitude: 40.80944, longitude: -73.96000, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:06:01', zoom_viz: 'primary', load: 0, load_wild: 0)
    nodes << nw.create_node(:um, ts: 0, bs_name: 'UMass', latitude: 42.39361, longitude: -72.53194, elevation: 80.0,
                   frequency: 2610.0, bw: 10.0, oid: '44:51:DB:00:05:01', zoom_viz: 'primary', load: 0, load_wild: 0)


    nw.link_schema [[:ts, :float], [:load, :float], [:load_wild, :float]]
    links = []
    links << nw.create_link(:lr12, :r1, :r2, :ts => 0, :load => 0.0, :load_wild => 0)
    links << nw.create_link(:lr23, :r2, :r3, :ts => 0, :load => 0.25, :load_wild => 0)
    links << nw.create_link(:lr31, :r3, :r1, :ts => 0, :load => 0.25, :load_wild => 0)

    links << nw.create_link(:lg12, :g1, :g2, :ts => 0, :load => 0.5, :load_wild => 0)

    links << nw.create_link(:lu12, :u1, :u2, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lw12, :w1, :w2, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lw13, :w1, :w3, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lw14, :w2, :w4, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lw15, :w2, :w5, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lw16, :w3, :w6, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lw17, :w3, :w7, :ts => 0, :load => 0.75, :load_wild => 0)
    #links << nw.create_link(:lw57, :w5, :w7, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lrp, :r1, :p1, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lru, :r1, :u1, :ts => 0, :load => 0.75, :load_wild => 0)
    links << nw.create_link(:lrw, :r1, :w1, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lwco, :w1, :co, :ts => 0, :load => 0.75, :load_wild => 0)

    links << nw.create_link(:lcou, :co, :u1, :ts => 0, :load => 0.75, :load_wild => 0)


    require 'omf_web'
    OMF::Web.register_datasource nw.to_table(:nodes, :index => :name)
    OMF::Web.register_datasource nw.to_table(:links, :index => :name)

    # Create a table which serves the history of an individual link or node as a slice
    #
    link_history = nw.to_table(:links, max_size: 1000)
    OMF::Web.register_datasource link_history, :name => 'link_history'
    node_history = nw.to_table(:nodes, max_size: 1000)
    OMF::Web.register_datasource node_history, :name => 'node_history'

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
            nodes.each_with_index do |n, i|
              n[:ts] = ts
              r = rand()
              n[:load] = r * frac + i * frac
              n[:load_wild] = r
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

