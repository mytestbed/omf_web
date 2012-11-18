require 'omf_web'
require 'omf_common/lobject'
require 'omf_oml/table'
require 'omf_oml/sql_source'


class PingDB < OMF::Common::LObject
  
  LINKS = {'Source1::192.168.4.11' => 'link 4',
            'Source1::192.168.5.11' => 'link 5',
            'Source2::192.168.1.13' => 'link 1',
            'Source2::192.168.2.10' => 'link 2',
            'Source2::192.168.4.10' => 'link 4',
            'Source3::192.168.2.12' => 'link 2',
            'Source3::192.168.3.12' => 'link 3',
            'Source3::192.168.5.12' => 'link 5',
            'Source3::192.168.6.12' => 'link 6',
            'Source4::192.168.1.13' => 'link 1',
            'Source4::192.168.3.12' => 'link 3',
            'Source5::192.168.6.12' => 'link 6'
          }
  
  def initialize(db_name)
    @db_name = db_name
  end
  
  def setup_table(stream)
    schema = stream.schema.clone
    schema.insert_column_at(0, :link)
    puts stream.schema.names.inspect
    
    t = OMF::OML::OmlTable.new(:ping, schema)
    stream.on_new_tuple() do |v|
      r = v.to_a(true)
      link_name = "#{v[:oml_sender]}::#{v[:dest_addr]}"
      #r.insert 0, LINKS[link_name] || "XXX - #{link_name}"
      r.insert 0, link_name
      t.add_row(r)   
    end
    OMF::Web.register_datasource t 
  end
  
  def run
    ep = OMF::OML::OmlSqlSource.new(@db_name, :check_interval => 3.0)
    ep.on_new_stream() do |stream|
      info "Stream: #{stream.stream_name}"
      if stream.stream_name == 'pingmonitor_myping'
        setup_table(stream)
      end
    end
    ep.run    
    self
  end
  
end
wv = PingDB.new('sqlite://example/simple/data_sources/gimi31.sq3').run()
