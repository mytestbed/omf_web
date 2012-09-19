
require 'omf_common/lobject'
require 'omf-oml/table'
require 'omf-oml/sql_source'
include OMF::OML

OMF::Common::Loggable.init_log 'test'

class WimaxViz < OMF::Common::LObject
  attr_reader :table
  
  def initialize(db_name)
    @db_name = db_name
  end
  
  def wimax_bss02_bs(stream)
    puts stream.class
    @table = stream.to_table(:wimax, :include_oml_internals => true)
    @table
    # require 'omf_web'
    # OMF::Web.register_datasource table
    
  end
  
  def run
    #ep = OMF::OML::OmlSqlSource.new(@db_name, :offset => -500, :check_interval => 1.0)
    ep = OMF::OML::OmlSqlSource.new(@db_name)
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
sleep 5
t = wv.table
puts t.rows.length
sleep 20
 
