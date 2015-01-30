require 'omf_web'
require 'omf_base/lobject'
require 'omf_oml/table'
require 'omf_oml/sql_source'

class WimaxStats < OMF::Base::LObject
  attr_reader :table

  def initialize(db_name)
    @db_name = db_name
  end

  def run
    #ep = OMF::OML::OmlSqlSource.new(@db_name, :offset => -500, :check_interval => 1.0)
    puts "Reading #{@db_name}"
    ep = OMF::OML::OmlSqlSource.new(@db_name, :offset => -1000, :check_interval => 30.0)
    ep.on_new_stream() do |stream|
      puts "STREAM: #{stream.stream_name}:#{stream.class}"
      case stream.stream_name
      when /^wimax_bss/ then
        @table = stream.to_table(:globalwimax, :include_oml_internals => true)
        OMF::Web.register_datasource @table
      when /^wimax_client/ then
        @table = stream.to_table(:localwimax, :include_oml_internals => true)
        OMF::Web.register_datasource @table
      else
        error("Don't know what to do with table '#{stream.stream_name}'")
      end
    end
    ep.run
    self
  end

end
