require 'singleton'
require 'omf_base/lobject'
require 'omf_oml/network'

module OMF::Web

  class DataSourceCreationException < OMFWebException
  end

  # This object helps to create data source objects from
  # a configuration hash. The avtually created data sources
  # are registered with DataSourceProxy
  #
  #
  class DataSourceFactory < OMF::Base::LObject
    include Singleton

    # Attempt to create a DataSource from 'ds_descr' and return it.
    # If this fails, throw an DataSourceCreationException or returns
    # nil if 'throw_exception' is set to false.
    #
    # If 'require_id' is set to false, an 'id' is automatically generated
    # and added to 'ds_descr' if it doesn't already exist.
    #
    # NOTE: If an OMSP type is declared, an OmspEndpointProxy instance is
    # returned instead.
    #
    def create(ds_descr, require_id = true, throw_exception = true)
      begin
        unless id = ds_descr[:id]
          if require_id
            fail "Missing id in datasource configuration"
          else
            id = ds_descr[:id] = "DataSource#{rand(10**12)}"
          end
        end
        if ds_descr[:database]
          load_database(id, ds_descr)
        elsif ds_descr[:file]
          load_datasource_file(id, ds_descr)
        elsif ds_descr[:omsp]
          load_omsp_endpoint(id, ds_descr)
        elsif ds_descr[:generator]
          load_generator(id, ds_descr[:generator])
        else
          fail "Unknown datasource type - #{ds_descr}"
        end
      rescue DataSourceCreationException => cex
        if throw_exception
          raise cex
        else
          debug "Can't create data source because of '#{cex.to_s}'"
          return nil
        end
      end
    end

    # Directory to use as anchor for relative file paths
    attr_accessor :cfg_dir

    protected

    def initialize()
      @databases = {}
      @cfg_dir = '.'
    end
    
    def fail(reason)
      raise DataSourceCreationException.new(reason)
    end
    
    def load_database(id, config)
      unless db_cfg = config[:database]
        fail "Missing database configuration in datasource '#{config}'"
      end
      db = get_database(db_cfg)
      if query_s = db_cfg[:query]
        unless schema = config[:schema]
          fail "Missing 'schema' definition in datasource configuration '#{config}'"
        end
        require 'omf_oml/schema'
        config[:schema] = OMF::OML::OmlSchema.create(schema)
        table = db.create_table(id, config)
      else
        unless table_name = db_cfg[:table]
          fail "Missing 'database/table' definition in datasource configuration '#{config}'"
        end
        #config[:name] = id
        unless table = db.create_table(table_name, config)
          fail "Can't find table '#{table_name}' in database '#{db_cfg}'"
        end
      end
      OMF::Web.register_datasource table, name: id
      table
    end

    def get_database(config)
      require 'omf_oml/table'
      require 'omf_oml/sql_source'
      if config.is_a? String
        if db = @databases[config]
          return db
        end
        fail "Database '#{config}' not defined - (#{@databases.keys})"
        
      end
      if id = config.delete(:id)
        if db = @databases[id.to_s] # already known
          return db
        end
      end

      # unless id = config[:id]
        # fatal "Database '#{config}' not defined - (#{@databases.keys})"
        # 
      # end
      unless url = config.delete(:url)
        fail "Missing URL for database '#{id}'"
        
      end
      if url.start_with?('sqlite:') && ! url.start_with?('sqlite:/')
        # inject top dir
        url.insert('sqlite:'.length, '//' + @cfg_dir + '/')
      end
      #config[:check_interval] ||= 3.0
      #puts "URL: #{url} - #{config}"
      begin
        db = OMF::OML::OmlSqlSource.new(url, config)
        @databases[id] = db if id
        return db
      rescue Exception => ex
        # TODO: Should catch load errors regarding database adapters
        # LoadError: cannot load such file -- pg
        fail "Can't connect to database '#{id}' - #{ex}"
        
      end
    end

    # The data to be served as a datasource is contained in a file. We
    # currently support CSV with headers, and JSON which turns into a
    # 1 col by 1 row datasource.
    #
    def load_datasource_file(name, opts)
      unless file = opts[:file]
        fail "Data source file is not defined in '#{opts}'"
      end
      if (handler = OMF::Web::SessionStore[:contentHandler, :repos])
        unless cd = handler.call(file)
          fail "Can't load data source file '#{opts}' through repo handler"
        end
        content_type = cd[:mime_type]
        content = cd[:content]
      else
        unless file.start_with? '/'
          file = File.absolute_path(file, @cfg_dir)
        end
        unless File.readable? file
          fail "Can't read file '#{file}'"
        end
        content = file.read
        unless content_type = opts[:content_type]
          ext = File.extname(file)[1 ..  -1]
          content_type = OMF::Web::ContentRepository::MIME_TYPE[ext] || 'text'
        end
      end
      case content_type.to_s
      when 'text/json'
        ds = JSONDataSource.new(content)
      when 'text/csv'
        require 'omf_oml/csv_table'
        ds = OMF::OML::OmlCsvTable.new name, nil, text: content, has_csv_header: true
      else
        fail "Unknown content type '#{content_type}'"
      end
      OMF::Web.register_datasource ds, name: name
      ds
    end

    def load_omsp_endpoint(id, config)
      oconfig = config[:omsp]
      unless port = oconfig[:port]
        fail "Need port in OMSP definition '#{oconfig}' - datasource '#{id}'"
        
      end
      ep = @omsp_endpoints[port] ||= OmspEndpointProxy.new(port)
      ep.add_datasource(id, config)
      ep
    end

    def load_generator(id, config)
      if file = config[:load]
        load_ruby_file(file)
      end
      unless klass_name = config[:class]
        fail "Missing 'class' options for generator '#{id}'"
      end
      klass = nil
      begin
        klass = Kernel.const_get(klass_name)
      rescue
        fail "Can't find class '#{klass_name}' referenced in generator '#{id}'"
        
      end
      opts = config[:opts] || {}
      debug "Creating new generator '#{id}' from '#{klass_name}' with '#{opts}'"
      unless klass.respond_to? :create_data_source
        fail "Class '#{klass_name}' doesn't have a 'create_data_source' class method."
      end
      klass.create_data_source(id, opts)
    end

    def load_ruby_file(file)
      unless file.start_with? '/'
        file = File.absolute_path(file, @cfg_dir)
      end
      unless File.readable? file
        fail "Can't read file '#{file}'"
        abort
      end
      debug "Loading #{file}"
      load(file)
    end


    # This class simulates a DataSource to transfer a JSON file as a database with one row and column
    #
    class JSONDataSource < OMF::Base::LObject

      def initialize(string)
        @content = [[JSON.parse(string)]]
      end

      #  * rows Returns an array of rows
      #  * on_content_changed(lambda{action, rows}) Call provided block with actions :added, :removed
      #  * create_sliced_table (optional)
      #  * release Not exactly sure when that is being used
      #  * schema Schema of row
      #  * offset
      def rows
        @content
      end

      def offset
        0
      end

      def schema
        require 'omf_oml/schema'
        OMF::OML::OmlSchema.create([[:content]])
      end

      def on_content_changed(*args)
        # do nothing
      end
    end

    # This class manages an OMSP Endpoint and all the related
    # data sources
    #
    class OmspEndpointProxy < OMF::Base::LObject
      def initialize(port)
        @streams = {}
        @sources = {}
        @tables = {}
        require 'omf_oml/endpoint'
        @ep = OMF::OML::OmlEndpoint.new(port)
        @ep.on_new_stream() do |name, stream|
          _on_new_stream(name, stream)
        end
        Thread.new do # delay starting up endpoint, can't use EM yet
          sleep 2
          @ep.run(false)
        end
      end

      def add_datasource(name, config)
        stream_name = config[:omsp][:stream_name] || name
        config.delete(:omsp)
        (@sources[stream_name.to_s] ||= []) << config
      end

      def _on_new_stream(name, stream)
        debug "New stream: #{name}-#{stream}"
        (@sources[name] || []).each do |tdef|
          puts "TDEF: #{tdef}"
          tname = tdef.dup.delete(:id)
          unless table = @tables[tname]
            table = @tables[tname] = stream.create_table(tname, tdef)
            OMF::Web.register_datasource table
            puts "ADDED: #{table}"
          else
            warn "Looks like reconnection, should reconnect to table as well"
          end
        end
      end

    end # class OmspEndpointProxy

  end #class
end # module
