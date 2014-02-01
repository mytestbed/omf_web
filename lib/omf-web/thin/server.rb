require 'json'
require 'omf_base/lobject'
require 'omf_web'

module OMF::Web

  # Most of the code to run an OMF Web server from a configuration file
  #
  # USAGE:
  #
  #
  class Server < OMF::Base::LObject

    def self.start(server_name, description, top_dir, opts = {})
      self.new(server_name, description, top_dir, opts)
    end

    def initialize(server_name, description, top_dir, opts)
      OMF::Base::Loggable.init_log(server_name)
      #OMF::Base::Loggable.init_log server_name
      opts = {
        handlers: {
          pre_parse: lambda do |p, runner|
            p.on("--config CONF_FILE", "File holding description of web site") {|f| runner.options[:omf_config_file] = f}
            p.on("--top-dir DIR", "Directory to start from for relative data paths [directory of config file]") {|td| @top_dir = td }
          end,
          post_parse: lambda { |r| load_environment(r.options) },
        },
        authentication: {
          required: false
        }
      }.merge(opts)

      @server_name = server_name
      @top_dir = top_dir
      @databases = {}
      @omsp_endpoints = {}

      OMF::Web.start(opts)
    end

    def load_environment(opts)
      unless cf = opts[:omf_config_file]
        puts "Missing config file"
        abort
      end

      unless File.readable? cf
        puts "Can't read config file '#{cf}'"
        abort
      end

      @cfg_dir = File.dirname(cf)
      opts[:static_dirs].insert(0, File.absolute_path(File.join(@cfg_dir, 'htdocs')))
      @top_dir ||= @cfg_dir
      cfg = _rec_sym_keys(YAML.load_file(cf))

      if log_opts = cfg[:logging]
        # TODO: Deal with custom logging option
      end

      (cfg[:server] || {}).each do |k, v|
        k = k.to_sym
        case k
        when :port
          opts[:port] = v.to_i
        else
          opts[k] = v
        end
      end
      (cfg[:data_sources] || []).each do |ds|
        load_datasource(ds)
      end
      (cfg[:repositories] || []).each do |repo|
        load_repository(repo)
      end

      widgets = cfg[:widgets] || []
      if (tabs = cfg[:tabs])
        tabs.each {|t| t[:top_level] = true}
        widgets += tabs
      end
      if widgets.empty?
        puts "Can't find 'widgets' or 'tabs' section in config file '#{cf}' - #{cfg.keys}"
        abort
      end
      widgets.each do |w|
        register_widget w
      end
    end

    def load_datasource(config)
      unless id = config[:id]
        puts "Missing id in datasource configuration"
        abort
      end
      if config[:database]
        load_database(id, config)
      elsif config[:file]
        load_datasource_file(id, config)
      elsif config[:omsp]
        load_omsp_endpoint(id, config)
      else
        abort "Unknown datasource type - #{config}"
      end
    end

    def load_database(id, config)
      unless db_cfg = config[:database]
        puts "Missing database configuration in datasource '#{config}'"
        abort
      end
      db = get_database(db_cfg)
      if query_s = config[:query]
        unless schema = config[:schema]
          puts "Missing schema configuration in datasource '#{config}'"
          abort
        end
        require 'omf_oml/schema'
        config[:schema] = OMF::OML::OmlSchema.create(schema)
        table = db.create_table(id, config)
      else
        unless table_name = config.delete(:table)
          puts "Missing 'table' in datasource configuration '#{config}'"
          abort
        end
        config[:name] = id
        unless table = db.create_table(table_name, config)
          puts "Can't find table '#{table_name}' in database '#{db_cfg}'"
          abort
        end
      end
      OMF::Web.register_datasource table, name: id
    end

    def get_database(config)
      require 'omf_oml/table'
      require 'omf_oml/sql_source'

      if config.is_a? String
        if db = @databases[config]
          return db
        end
        puts "Database '#{config}' not defined - (#{@databases.keys})"
        abort
      end
      if id = config.delete(:id)
        if db = @databases[id.to_s] # already known
          return db
        end
      end

      # unless id = config[:id]
        # puts "Database '#{config}' not defined - (#{@databases.keys})"
        # abort
      # end
      unless url = config.delete(:url)
        puts "Missing URL for database '#{id}'"
        abort
      end
      if url.start_with?('sqlite:') && ! url.start_with?('sqlite:/')
        # inject top dir
        url.insert('sqlite:'.length, '//' + @cfg_dir + '/')
      end
      config[:check_interval] ||= 3.0
      puts "URL: #{url} - #{config}"
      begin
        db = OMF::OML::OmlSqlSource.new(url, config)
        @databases[id] = db if id
        return db
      rescue Exception => ex
        puts "Can't connect to database '#{id}' - #{ex}"
        abort
      end
    end

    # The data to be served as a datasource is contained in a file. We
    # currently support CSV with headers, and JSON which turns into a
    # 1 col by 1 row datasource.
    #
    def load_datasource_file(name, opts)
      unless file = opts[:file]
        puts "Data source file is not defined in '#{opts}'"
        abort
      end
      unless file.start_with? '/'
        file = File.join(@cfg_dir, file)
      end
      unless File.readable? file
        puts "Can't read file '#{file}'"
        abort
      end
      unless content_type = opts[:content_type]
        content_type = File.extname(file)[1 ..  -1]
      end
      case content_type.to_s
      when 'json'
        ds = JSONDataSource.new(file)
      when 'csv'
        require 'omf_oml/csv_table'
        ds = OMF::OML::OmlCsvTable.create name, file, has_csv_header: true
      else
        puts "Unknown content type '#{content_type}'"
        abort
      end
      OMF::Web.register_datasource ds, name: name
    end

    def load_omsp_endpoint(id, config)
      oconfig = config[:omsp]
      unless port = oconfig[:port]
        puts "Need port in OMSP definition '#{oconfig}' - datasource '#{id}'"
        abort
      end
      ep = @omsp_endpoints[port] ||= OmspEndpointProxy.new(port)
      ep.add_datasource(id, config)
    end


    def load_repository(config)
      unless id = config[:id]
        puts "Missing id in respository configuration"
        abort
      end
      unless type = config[:type]
        puts "Missing 'type' in respository configuration '#{id}'"
        abort
      end

      require 'omf-web/content/repository'
      case type
      when 'file'
        unless top_dir = config[:top_dir]
          puts "Missing 'top_dir' in respository configuration '#{id}'"
          abort
        end
        unless top_dir.start_with? '/'
          top_dir = File.join(@top_dir, top_dir)
        end
        OMF::Web::ContentRepository.register_repo(id, type: :file, top_dir: top_dir)
      else
        puts "Unknown repository type '#{type}'. Only supporting 'file'."
        abort
      end

    end

    def register_widget(w)
      unless w[:id]
        require 'digest/md5'
        w[:id] = Digest::MD5.hexdigest(w[:name] || "tab#{rand(10000)}")[0, 8]
      end
      w[:top_level] = true
      w[:type] ||= 'layout/one_column'
      OMF::Web.register_widget w
    end

    # Recusively Symbolize keys of hash
    #
    def _rec_sym_keys(hash)
      h = {}
      hash.each do |k, v|
        if v.is_a? Hash
          v = _rec_sym_keys(v)
        elsif v.is_a? Array
          v = v.map {|e| e.is_a?(Hash) ? _rec_sym_keys(e) : e }
        end
        h[k.to_sym] = v
      end
      h
    end


    # This class simulates a DataSource to transfer a JSON file as a database with one row and column


    class JSONDataSource < OMF::Base::LObject

      def initialize(file)
        raw = File.read(file)
        @content = [[JSON.parse(raw)]]
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

  end # class
end # module
