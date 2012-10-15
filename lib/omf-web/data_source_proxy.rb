

require 'omf_common/lobject'
require 'omf_oml/network'

module OMF::Web
        
  # This object maintains synchronization between a JS DataSource object 
  # in a web browser and the corresponding +OmlTable+ in this server.
  #
  #
  class DataSourceProxy < OMF::Common::LObject
    
    @@datasources = {}
    
    # Register a data source.
    #
    # params data_source - Data source to register
    # params opts:
    #          name - Name to use instead of data source's native name
    #
    def self.register_datasource(data_source, opts = {})
      name = (opts[:name] || data_source.name).to_sym
      if (@@datasources.key? name)
        raise "Repeated try to register data source '#{name}'"
      end
      if data_source.is_a? OMF::OML::OmlNetwork
        raise "Register link and node table separately "
      end
        # dsh = data_source.to_tables(opts)
        # @@datasources[name] = dsh
      # else
        # @@datasources[name] = data_source
      # end
      @@datasources[name] = data_source      
    end
    
    def self.[](name)
      name = name.to_sym
      unless dsp = OMF::Web::SessionStore[name, :dsp]
        if ds = @@datasources[name]
          dsp = OMF::Web::SessionStore[name, :dsp] = self.new(name, ds)
        else
          warn "Requesting unknown datasource '#{name}', only know about '#{@@datasources.keys.join(', ')}'."
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
      unless ds_name = ds_descr[:name]
        raise "Missing 'name' attribute in datasource description. (#{ds_descr.inspect})"
      end
      ds_name = ds_name.to_sym
      ds = @@datasources[ds_name]
      unless ds
        top = "#{ds_name}/"
        names = @@datasources.keys.find_all { |ds_name| ds_name.to_s.start_with? top }
        unless names.empty?
          return names.map do |ds_name| 
            OMF::Web::SessionStore[ds_name, :dsp] ||= self.new(ds_name, @@datasources[ds_name]) 
          end
        end
        # debug ">>>> #{dsa}"
        # # let's check for sub table, such as network/nodes
        # main, sub = ds_descr[:name].split('/')
        # if (sub)
          # if ds_top = @@datasources[main.to_sym]
            # ds = ds_top[sub.to_sym]
          # end
        # end
        unless ds
          raise "Unknown data source '#{ds_name}' (#{@@datasources.keys.inspect})"
        end
      end
      if ds.is_a? Hash
        raise "Is this actually used anywhere?"
        proxies = ds.map do |name, ds|
          id = "#{ds_name}_#{name}".to_sym
          proxy = OMF::Web::SessionStore[id, :dsp] ||= self.new(id, ds)
        end
        return proxies
      end
      
      #debug ">>>>> DS: #{ds_descr.inspect} - #{ds}"
      proxy = OMF::Web::SessionStore[ds_name, :dsp] ||= self.new(ds_name, ds)
      return [proxy]
    end
    
    attr_reader :name
    
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
        block.call :added, rows
      end
      @data_source.on_content_changed(block.object_id) do |action, rows|
        debug "on_changed: #{action}: #{rows.inspect}"
        block.call action, rows
      end
    end
    
    # Create a new data source which only contains a slice of the underlying data source
    def create_slice(col_name, col_value)
      ds = @data_source.create_sliced_table(col_name, col_value)
      dsp = self.class.new(ds.name, ds)
      def dsp.release; @data_source.release end
      dsp
    end
    
    def to_javascript(opts = {})
      #puts "to_java>>>>> #{opts.inspect}"
      sid = Thread.current["sessionID"]
      opts = opts.dup
      opts[:name] = @name
      opts[:schema] = @data_source.schema
      opts[:update_url] = "/_update/#{@name}?sid=#{sid}"
      opts[:sid] = sid
      unless opts[:slice] # don't send any data if this is a sliced one
        #opts[:rows] = @data_source.rows[0 .. 20]
        opts[:rows] = []
        opts[:offset] = @data_source.offset
      end
      #puts "to_java2>>>>> #{opts.to_json.inspect}"
      
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
