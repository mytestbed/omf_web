require 'omf_web'
require 'omf_base/lobject'
require 'omf_oml/network'
require 'omf_oml/table'
require 'omf_oml/sql_source'

#require 'em-postgresql-sequel'


include OMF::OML

class ExpDB < OMF::Base::LObject


  def initialize(db_opts)
    @db_opts = db_opts
    init_network
  end

  def init_network
    @nw = nw = OmlNetwork.new('network')
    nw.node_schema [[:x, :float], [:y, :float]]
    nw.create_node :n0, :x => 0.5, :y => 0.8
    nw.create_node :n1, :x => 0.2, :y => 0.5
    nw.create_node :n2, :x => 0.8, :y => 0.5
    nw.create_node :n3, :x => 0.8, :y => 0.2

    nw.link_schema [[:ts, :float], [:bytes, :int], [:rate, :float], [:load, :float]]
    @links = {}
    @links[:l20] = nw.create_link(:l20, :n2, :n0, :ts => 0, :bytes => 0, :rate => 0, :load => 0)
    @links[:l10] = nw.create_link(:l10, :n1, :n0, :ts => 0, :bytes => 0, :rate => 0, :load => 0)
    @links[:l21] = nw.create_link(:l21, :n2, :n1, :ts => 0, :bytes => 0, :rate => 0, :load => 0)
    @links[:l32] = nw.create_link(:l32, :n3, :n2, :ts => 0, :bytes => 0, :rate => 0, :load => 0)


    OMF::Web.register_datasource nw.to_table(:nodes, :index => :id)
    OMF::Web.register_datasource nw.to_table(:links, :index => :id)
    @link_history = nw.to_table(:links, :max_size => 100)
    OMF::Web.register_datasource @link_history, :name => 'link_history'
  end

  def setup_nmetric(stream)
    schema = stream.schema
    t = OMF::OML::OmlTable.new(:nmetric, schema, :max_size => 1000)
    ts_i = schema.index_for_col(:oml_ts_server)
    name_i = schema.index_for_col(:name)
    tx_i = schema.index_for_col(:tx_bytes)
    rx_i = schema.index_for_col(:rx_bytes)

    def process(l, ts, bytes, max_rate)
      if (delta_t = ts - l[:ts]) > 0
        old_v = l[:bytes]
        delta_v = bytes >= old_v ? bytes - old_v : bytes
        l[:ts] = ts
        l[:bytes] = bytes
        l[:rate] = rate = 1.0 * delta_v / delta_t
        #l[:rate] = rate = 230000
        l[:load] = 1.0 * rate / max_rate
      end
    end

    stream.on_new_tuple() do |v|
      r = v.to_a(schema)

      t.add_row(r)
      ts = r[ts_i]; name = r[name_i].to_sym; tx = r[tx_i]; rx = r[rx_i]
      #puts "VVV(#{ts}) >> #{v.row.inspect}"
      @nw.transaction do
        case name
        when :eth0
          process @links[:l20], ts, tx, 120e3 #1e6
        when :wlan0
          process @links[:l21], ts, tx, 4e6
          process @links[:l10], ts, tx, 4e6
        when :wlan1
          process @links[:l32], ts, rx, 4e6
        end
      end
      sleep 0.5 if ts > 7300
    end

      # nw.transaction do
        # links.each_with_index do |l, i|
          # l[:ts] = ts
          # l[:load] = rand() * frac + i * frac
        # end
      # end

    OMF::Web.register_datasource t
  end

  def process_nmetric(table)
    schema = table.schema
    ts_i = schema.index_for_col(:oml_ts_server)
    name_i = schema.index_for_col(:name)
    tx_i = schema.index_for_col(:tx_bytes)
    rx_i = schema.index_for_col(:rx_bytes)

    def process(l, ts, bytes, max_rate)
      if (delta_t = ts - l[:ts]) > 0
        old_v = l[:bytes]
        delta_v = bytes >= old_v ? bytes - old_v : bytes
        l[:ts] = ts
        l[:bytes] = bytes
        l[:rate] = rate = 1.0 * delta_v / delta_t
        #l[:rate] = rate = 230000
        l[:load] = 1.0 * rate / max_rate
      end
    end

    table.on_row_added(self) do |r|
      ts = r[ts_i]; name = r[name_i].to_sym; tx = r[tx_i]; rx = r[rx_i]
      @nw.transaction do
        case name
        when :eth0
          process @links[:l20], ts, tx, 120e3 #1e6
        when :wlan0
          process @links[:l21], ts, tx, 4e6
          process @links[:l10], ts, tx, 4e6
        when :wlan1
          process @links[:l32], ts, rx, 4e6
        end
      end
      sleep 0.5 if ts > 7300
    end
    OMF::Web.register_datasource table, name: 'nmetric'
  end

  def run
    ep = OMF::OML::OmlSqlSource.new(@db_opts, :check_interval => 3.0)
    t = ep.create_table('nmetrics_net_if', include_oml_internals: true, max_size: 1000)
    process_nmetric(t)
    # ep.on_new_stream() do |stream|
      # info "Stream: #{stream.stream_name}"
      # if stream.stream_name == 'nmetrics_net_if'
        # setup_nmetric(stream)
      # end
    # end
    # ep.run
    self
  end

end
