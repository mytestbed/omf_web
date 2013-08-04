#!/usr/bin/env ruby
BIN_DIR = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
TOP_DIR = File.join(BIN_DIR, '..')
$: << File.join(TOP_DIR, 'lib')

DESCR = %{
Start an OMF WEB site ...
}

require 'omf_common/lobject'
require 'omf_oml/table'
require 'omf_oml/sql_source'


OMF::Common::Loggable.init_log 'omf_web'

$config_file_dir = nil

require 'omf_oml/table'

def load_environment(opts)
  unless cf = opts[:omf_config_file]
    puts "Missing config file"
    abort
  end

  unless File.readable? cf
    puts "Can't read config file '#{cf}'"
    abort
  end

  $config_file_dir = File.dirname(cf)
  cfg = YAML.load_file(cf)
  (cfg['server'] || {}).each do |k, v|
    k = k.to_sym
    case k
    when :port
      opts[:port] = v.to_i
    else
      opts[k] = v
    end
  end
  databases = {}
  (cfg['data_sources'] || []).each do |ds|
    load_datasource(ds, databases)
  end
  (cfg['repositories'] || []).each do |repo|
    load_repository(repo)
  end

  unless wa = cfg['widgets']
    puts "Can't find 'widgets' section in config file '#{cf}' - #{cfg.keys}"
    abort
  end
  wa.each do |w|
    OMF::Web.register_widget w
  end
end

def load_datasource(config, databases)
  unless id = config['id']
    puts "Missing id in datasource configuration"
    abort
  end
  unless table_name = config['table']
    puts "Missing 'table' in datasource configuration '#{id}'"
    abort
  end
  unless db_cfg = config['database']
    puts "Missing database configuration in datasource '#{id}'"
    abort
  end
  db = get_database(db_cfg, databases)
  unless table = db.create_table(table_name)
    puts "Can't find table '#{table_name}' in database '#{db}'"
    abort
  end
  OMF::Web.register_datasource table, name: id
end

def get_database(config, databases)
  if config.is_a? String
    if db = databases[config]
      return db
    end
    puts "Database '#{config}' not defined - (#{databases.keys})"
    abort
  end
  unless id = config['id']
    puts "Missing id in database configuration"
    abort
  end
  unless id = config['id']
    puts "Database '#{config}' not defined - (#{databases.keys})"
    abort
  end
  unless url = config['url']
    puts "Missing URL for database '#{id}'"
    abort
  end
  if url.start_with?('sqlite://') && ! url.start_with?('sqlite:///')
    # inject top dir
    url.insert('sqlite://'.length, $config_file_dir + '/')
  end
  puts "URL: #{url}"
  begin
    return databases[id] = OMF::OML::OmlSqlSource.new(url, :check_interval => 3.0)
  rescue Exception => ex
    puts "Can't connect ot database '#{id}' - #{ex}"
    abort
  end
end

def load_repository(config)
  unless id = config['id']
    puts "Missing id in respository configuration"
    abort
  end
  unless type = config['type']
    puts "Missing 'type' in respository configuration '#{id}'"
    abort
  end

  require 'omf-web/content/repository'
  case type
  when 'file'
    unless top_dir = config['top_dir']
      puts "Missing 'top_dir' in respository configuration '#{id}'"
      abort
    end
    unless top_dir.start_with? '/'
      top_dir = File.join($config_file_dir, top_dir)
    end
    OMF::Web::ContentRepository.register_repo(id, type: :file, top_dir: top_dir)
  else
    puts "Unknown repository type '#{type}'. Only supporting 'file'."
    abort
  end
end

# Configure the web server
#
opts = {
  app_name: 'simple',
  page_title: 'Simple Demo',
  port: 4000,
  handlers: {
    pre_parse: lambda do |p, runner|
      p.on("--config CONF_FILE", "File holding description of web site") {|f| runner.options[:omf_config_file] = f}
    end,
    # delay connecting to databases to AFTER we may run as daemon
    post_parse: lambda { |r| load_environment(r.options) },
  }
}
require 'omf_web'
OMF::Web.start(opts)
