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
            p.on("--example [EXAMPLE]", "Run an example [#{list_of_examples.join(', ')}]")  do |e|
              unless e
                puts "Available examples: #{list_of_examples.join(', ')}"
                exit 0
              end
              runner.options[:omf_config_file] = "example:#{e}"
            end
          end
        },
        authentication: {
          required: false
        }
      }.merge(opts)
      post_parse = opts[:handlers][:post_parse]
      opts[:handlers][:post_parse] = lambda do |r|
        post_parse.call(r) if post_parse
        load_environment(r.options)
      end
      @server_name = server_name
      @top_dir = top_dir
      @databases = {}
      @omsp_endpoints = {}

      OMF::Web.start(opts)
    end

    def load_environment(opts)
      unless cf = opts[:omf_config_file]
        fatal "Missing config file '--config'"
        abort
      end

      unless File.readable? cf
        unless cf2 = check_for_builtin(cf, opts)
          fatal "Can't read config file '#{cf}'"
          abort
        end
        cf = cf2 # found a builtin config file
      end

      @cfg_dir = File.dirname(cf)
      opts[:static_dirs].insert(0, File.absolute_path(File.join(@cfg_dir, 'htdocs')))
      @top_dir ||= @cfg_dir
      load_config_file(cf, opts)
    end

    def check_for_builtin(cf, opts)
      pa = cf.split(':')
      unless pa.length == 2 && pa[0] == 'example'
        return nil
      end
      path = File.join(@top_dir, 'example', pa[1])
      if File.directory? path
        dir = path
        path = File.join(dir, "#{pa[1]}.yaml")
        unless File.readable? path
          # check .yml
          path = File.join(dir, "#{pa[1]}.yml")
        end
      end
      unless File.readable?(path)
        da = list_of_examples
        ex = pa[1].split('/')[0]
        if da.include? ex
          ya = Dir.glob(File.join(@top_dir, 'example', ex, '*.yaml')).map do |fn|
            File.basename(fn)
          end
          fatal "Unknown config file. Did you mean '#{ya.join(', ')}'?"
        else
          fatal "Unknown example '#{}'. Did you mean '#{da.join(', ')}'?"
        end
        abort
      end
      return path
    end

    def list_of_examples()
      Dir.entries(File.join(@top_dir, 'example')).select do |n|
        !(n == 'NOT_WORKING' || n.start_with?('.'))
      end
    end

    def load_config_file(cf, opts)
      debug "Loading config file '#{cf}'"
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
      # if widgets.empty?
        # fatal "Can't find 'widgets' or 'tabs' section in config file '#{cf}' - #{cfg.keys}"
        # abort
      # end
      widgets.each do |w|
        register_widget w
      end

      # Any other file to load before opening shop
      if load = cfg[:load]
        unless load.is_a? Enumerable
          load = [load]
        end
        load.each do |g| #{|f| load_ruby_file(f) }
          unless g.start_with? '/'
            g = File.absolute_path(g, File.dirname(cf))
          end
          found_something = false
          Dir.glob(g).each do |f|
            found_something = true
            load_ruby_file(f)
          end
          unless found_something
            fatal "Couldn't find any load file for pattern '#{g}'"
            abort
          end
        end
      end

      # Any other configure to load
      if include = cfg[:include]
        unless include.is_a? Enumerable
          include = [include]
        end
        include.each do |g|
          unless g.start_with? '/'
            g = File.absolute_path(g, File.dirname(cf))
          end
          found_something = false
          Dir.glob(g).each do |f|
            found_something = true
            load_config_file(f, opts)
          end
          unless found_something
            fatal "Couldn't find any config file for pattern '#{g}'"
            abort
          end
        end
      end

    end

    def load_datasource(config)
      unless id = config[:id]
        fatal "Missing id in datasource configuration"
        abort
      end
      if config[:database]
        load_database(id, config)
      elsif config[:file]
        load_datasource_file(id, config)
      elsif config[:omsp]
        load_omsp_endpoint(id, config)
      elsif config[:generator]
        load_generator(id, config[:generator])
      else
        abort "Unknown datasource type - #{config}"
      end
    end

    def load_database(id, config)
      unless db_cfg = config[:database]
        fatal "Missing database configuration in datasource '#{config}'"
        abort
      end
      db = get_database(db_cfg)
      if query_s = config[:query]
        unless schema = config[:schema]
          fatal "Missing schema configuration in datasource '#{config}'"
          abort
        end
        require 'omf_oml/schema'
        config[:schema] = OMF::OML::OmlSchema.create(schema)
        table = db.create_table(id, config)
      else
        unless table_name = config.delete(:table)
          fatal "Missing 'table' in datasource configuration '#{config}'"
          abort
        end
        config[:name] = id
        unless table = db.create_table(table_name, config)
          fatal "Can't find table '#{table_name}' in database '#{db_cfg}'"
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
        fatal "Database '#{config}' not defined - (#{@databases.keys})"
        abort
      end
      if id = config.delete(:id)
        if db = @databases[id.to_s] # already known
          return db
        end
      end

      # unless id = config[:id]
        # fatal "Database '#{config}' not defined - (#{@databases.keys})"
        # abort
      # end
      unless url = config.delete(:url)
        fatal "Missing URL for database '#{id}'"
        abort
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
        fatal "Can't connect to database '#{id}' - #{ex}"
        abort
      end
    end

    # The data to be served as a datasource is contained in a file. We
    # currently support CSV with headers, and JSON which turns into a
    # 1 col by 1 row datasource.
    #
    def load_datasource_file(name, opts)
      unless file = opts[:file]
        fatal "Data source file is not defined in '#{opts}'"
        abort
      end
      unless file.start_with? '/'
        file = File.absolute_path(file, @cfg_dir)
      end
      unless File.readable? file
        fatal "Can't read file '#{file}'"
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
        fatal "Unknown content type '#{content_type}'"
        abort
      end
      OMF::Web.register_datasource ds, name: name
    end

    def load_omsp_endpoint(id, config)
      oconfig = config[:omsp]
      unless port = oconfig[:port]
        fatal "Need port in OMSP definition '#{oconfig}' - datasource '#{id}'"
        abort
      end
      ep = @omsp_endpoints[port] ||= OmspEndpointProxy.new(port)
      ep.add_datasource(id, config)
    end

    def load_generator(id, config)
      if file = config[:load]
        load_ruby_file(file)
      end
      unless klass_name = config[:class]
        fatal "Missing 'class' options for generator '#{id}'"
        abort
      end
      klass = nil
      begin
        klass = Kernel.const_get(klass_name)
      rescue
        fatal "Can't find class '#{klass_name}' referenced in generator '#{id}'"
        abort
      end
      opts = config[:opts] || {}
      debug "Creating new generator '#{id}' from '#{klass_name}' with '#{opts}'"
      unless klass.respond_to? :create_data_source
        fatal "Class '#{klass_name}' doesn't have a 'create_data_source' class method."
        abort
      end
      klass.create_data_source(id, opts)
    end

    def load_ruby_file(file)
      unless file.start_with? '/'
        file = File.absolute_path(file, @cfg_dir)
      end
      unless File.readable? file
        fatal "Can't read file '#{file}'"
        abort
      end
      debug "Loading #{file}"
      load(file)
    end


    def load_repository(config)
      unless id = config[:id]
        fatal "Missing id in respository configuration"
        abort
      end
      unless type = config[:type]
        fatal "Missing 'type' in respository configuration '#{id}'"
        abort
      end

      require 'omf-web/content/repository'
      case type
      when 'file'
        unless top_dir = config[:top_dir]
          fatal "Missing 'top_dir' in respository configuration '#{id}'"
          abort
        end
        unless top_dir.start_with? '/'
          top_dir = File.join(@cfg_dir, top_dir)
        end
        #puts "TOP>>> #{File.absolute_path top_dir}"
        OMF::Web::ContentRepository.register_repo(id, type: :file, top_dir: top_dir)
      else
        fatal "Unknown repository type '#{type}'. Only supporting 'file'."
        abort
      end

    end

    def register_widget(w)
      unless w[:id]
        require 'digest/md5'
        w[:id] = Digest::MD5.hexdigest(w[:name] || "tab#{rand(10000)}")[0, 8]
      end
      #w[:top_level] = true
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
