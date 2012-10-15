
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'wimax'

require 'omf_web'
require 'omf_common/lobject'
require 'omf_oml/table'
require 'omf_oml/sql_source'


class WimaxViz < OMF::Common::LObject
  attr_reader :table
  
  def initialize(db_name)
    @db_name = db_name
  end
  
  def wimax_bss02_bs(stream)
    puts stream.class
    @table = stream.to_table(:wimax, :include_oml_internals => true)
    OMF::Web.register_datasource @table    
  end
  
  def run
    #ep = OMF::OML::OmlSqlSource.new(@db_name, :offset => -500, :check_interval => 1.0)
    ep = OMF::OML::OmlSqlSource.new(@db_name, :check_interval => 3.0)
    ep.on_new_stream() do |stream|
      #puts stream.inspect
      case stream.stream_name
      when 'wimax_bss02_bs'
        wimax_bss02_bs(stream)
      else
        error(:oml, "Don't know what to do with table '#{stream.stream_name}'")
      end
    end
    ep.run
    self
  end
end
wv = WimaxViz.new('example/wimax/snapshot.db').run()
    


require 'yaml'
Dir.glob("#{File.dirname(__FILE__)}/*.yaml").each do |fn|
  h = YAML.load_file(fn)
  if w = h['widget']
    OMF::Web.register_widget w
  else
    OMF::Common::LObject.error "Don't know what to do with '#{fn}'"
  end
end


# Configure the web server
#
opts = {
  :page_title => 'WiMAX Operation',
}
require 'omf_web'
OMF::Web.start(opts)
