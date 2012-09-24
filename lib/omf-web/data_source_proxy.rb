

require 'omf_common/lobject'
require 'omf-oml/network'

module OMF::Web
        
  # This object maintains synchronization between a JS DataSource object 
  # in a web browser and the corresponding +OmlTable+ in this server.
  #
  #
  class DataSourceProxy < OMF::Common::LObject
    
    @@datasources = {}
    
    def self.register_datasource(data_source, opts = {})
      name = data_source.name.to_sym
      if (@@datasources.key? name)
        raise "Repeated try to register data source '#{name}'"
      end
      if data_source.is_a? OMF::OML::OmlNetwork
        dsh = data_source.to_tables(opts)
        @@datasources[name] = dsh
      else
        @@datasources[name] = data_source
      end
    end
    
    def self.[](name)
      name = name.to_sym
      unless dsp = OMF::Web::SessionStore[name, :dsp]
        if ds = @@datasources[name]
          dsp = OMF::Web::SessionStore[name, :dsp] = self.new(name, ds)
        end
      end
      dsp
    end
    
    # Return proxies for 'ds_name'. Note, there can be more then
    # one proxy be needed for a datasource, such as a network which
    # has one ds for the nodes and one for the links
    #
    # @return: Array of proxies
    #
    # TODO: This seems to hardcode networks.
    #
    def self.for_source(ds_descr)
      #raise "FOO #{ds_descr.inspect}"
      unless ds_descr.is_a? Hash
        raise "Expected Hash, but got '#{ds_descr.class}::#{ds_descr.inspect}'"
      end
      ds_name = ds_descr[:name].to_sym
      ds = @@datasources[ds_name]
      puts "FOR SOURCE>>>>> #{ds_descr.inspect}::#{ds.inspect}"
      unless ds
        # let's check for sub table, such as network/nodes
        main, sub = ds_descr[:name].split('/')
        puts "1>>> main #{main}, sub: #{sub}"
        if (sub)
          if ds_top = @@datasources[main.to_sym]
            puts "2>>>>> ds_top #{ds_top}"
            ds = ds_top[sub.to_sym]
          end
        end
        unless ds
          raise "Unknown data source '#{ds_name}' (#{@@datasources.keys.inspect})"
        end
      end
      if ds.is_a? Hash
        proxies = ds.map do |name, ds|
          id = "#{ds_name}_#{name}".to_sym
          proxy = OMF::Web::SessionStore[id, :dsp] ||= self.new(id, ds)
        end
        return proxies
          
        # n_name = "#{ds_name}_nodes".to_sym
        # l_name = "#{ds_name}_links".to_sym
        # if (nodes = OMF::Web::SessionStore[n_name, :dsp])
          # # assume links exist as well
          # links = OMF::Web::SessionStore[l_name, :dsp]                
        # else
          # nodes = OMF::Web::SessionStore[n_name, :dsp] = self.new(n_name, ds[:nodes])
          # links = OMF::Web::SessionStore[l_name, :dsp] = self.new(l_name, ds[:links])
        # end
        # return [nodes, links]
      end
      
      proxy = OMF::Web::SessionStore[ds_name, :dsp] ||= self.new(ds_name, ds)
      return [proxy]
    end
    
    def reset()
      # TODO: Figure out partial sending 
    end
    
    def on_update(req)
      res = {:events => @data_source.rows}
      [res.to_json, "text/json"]
    end
    
    # Register callback to be informed of changes to the underlying data source.
    # Call block when new rows are becoming available. Block needs ot return 
    # true if it wants to continue receiving updates.
    #
    # offset: Number of records already downloaded
    #
    def on_changed(offset, &block)
      ds = @data_source
      rows = ds.rows[(offset - ds.offset) .. -1]
      if rows && rows.length > 0
        debug "on_changed: sending #{rows.length}"
        block.call rows, ds.offset
      end
      @data_source.on_row_added(block.object_id) do |row, offset|
        debug "on_changed: more data: #{row.inspect}"
        block.call [row], offset
      end
    end
    
    
    def to_javascript(opts)
      puts "to_java>>>>> #{opts.inspect}"
      sid = Thread.current["sessionID"]
      opts = opts.dup
      opts[:name] = @name
      opts[:schema] = @data_source.schema
      opts[:update_url] = "/_update/#{@name}?sid=#{sid}"
      opts[:sid] = sid
      opts[:rows] = @data_source.rows[0 .. 20]
      opts[:offset] = @data_source.offset
      puts "to_java2>>>>> #{opts.to_json.inspect}"
      
      %{
        OML.data_sources.register(#{opts.to_json});
      }
     
    end
    
    def initialize(name, data_source)
      @name = name
      @data_source = data_source
    end
  end
  
end
