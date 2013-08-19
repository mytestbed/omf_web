require 'json'
require 'omf_common/lobject'
require 'omf_web'

module OMF::Web

  # Most of the code to run an OMF Web server from a configuration file
  #
  # USAGE:
  #
  #
  class Server < OMF::Common::LObject

    def self.start(server_name, description, top_dir, opts = {})
      self.new(server_name, description, top_dir, opts)
    end

    def initialize(server_name, description, top_dir, opts)
      OMF::Common::Loggable.init_log server_name

      opts = {
        static_dirs_pre: ["#{top_dir}/htdocs"],
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

      @top_dir = top_dir
      @databases = {}

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

      @top_dir ||= File.dirname(cf)
      cfg = _rec_sym_keys(YAML.load_file(cf))

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

      unless wa = cfg[:widgets]
        puts "Can't find 'widgets' section in config file '#{cf}' - #{cfg.keys}"
        abort
      end
      wa.each do |w|
        OMF::Web.register_widget w
      end
    end

    def load_datasource(config)
      unless id = config[:id]
        puts "Missing id in datasource configuration"
        abort
      end
      case type = config[:type] || 'database'
      when 'database'
        load_database(config)
      when 'file'
        load_datasource_file(id, config)
      else
        abort "Unknown datasource type '#{type}'."
      end
    end

    def load_database(config)
      unless table_name = config[:table]
        puts "Missing 'table' in datasource configuration '#{id}'"
        abort
      end
      unless db_cfg = config[:database]
        puts "Missing database configuration in datasource '#{id}'"
        abort
      end
      db = get_database(db_cfg)
      unless table = db.create_table(table_name)
        puts "Can't find table '#{table_name}' in database '#{db}'"
        abort
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
      unless id = config[:id]
        puts "Missing id in database configuration"
        abort
      end
      # unless id = config[:id]
        # puts "Database '#{config}' not defined - (#{@databases.keys})"
        # abort
      # end
      unless url = config[:url]
        puts "Missing URL for database '#{id}'"
        abort
      end
      if url.start_with?('sqlite://') && ! url.start_with?('sqlite:///')
        # inject top dir
        url.insert('sqlite://'.length, @top_dir + '/')
      end
      puts "URL: #{url}"
      begin
        return @databases[id] = OMF::OML::OmlSqlSource.new(url, :check_interval => 3.0)
      rescue Exception => ex
        puts "Can't connect ot database '#{id}' - #{ex}"
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
        file = File.join(@top_dir, file)
      end
      unless File.readable? file
        puts "Can't read file '#{file}'"
        abort
      end
      case content_type = opts[:content_type].to_s
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


    class JSONDataSource < OMF::Common::LObject

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
  end # class
end # module