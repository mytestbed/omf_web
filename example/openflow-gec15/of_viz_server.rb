
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'of-demo'


require 'omf_oml/table'

$testing_database = 'sqlite://example/openflow-gec15/openflow-demo.sq3'
$oml_database = 'postgres://norbit.npc.nicta.com.au/openflow-demo?user=oml2&password=omlisgoodforyou'

def load_environment
  require 'omf-web/content/file_repository'
  OMF::Web::ContentRepository.register_repo(:code, type: 'file', path: File.join(File.dirname(__FILE__), 'repository'))
  

  Dir.glob("#{File.dirname(__FILE__)}/*_source.rb").each do |fn|
    load fn
  end
  
  require 'yaml'
  Dir.glob("#{File.dirname(__FILE__)}/*_tab.yaml").each do |fn|
    h = YAML.load_file(fn)
    if w = h['widget']
      OMF::Web.register_widget w
    else
      MObject.error "Don't know what to do with '#{fn}'"
    end
  end
   
  # Start database adapter
  EM.next_tick do
    EM::run do
      wv = ExpDB.new($oml_database)
      wv.run
    end
  end
end


# Configure the web server
#
opts = {
  :app_name => 'ov_demo',
  :page_title => 'Dynamic Routing',
  :handlers => {
    # delay connecting to databases to AFTER we may run as daemon
    :pre_rackup => lambda { load_environment },
    :pre_parse => lambda do |p|
      p.separator ""
      p.separator "DEMO options:"
      p.on("--local-testing", "If set, use local database for testing [#{$testing_database}]") do
        $oml_database = $testing_database
      end
      p.on("--oml-database DATABASE", "Database containing measurement data [#{$oml_database}]") do |f|
        $oml_database = f
      end
      p.separator ""
    end
    
  }
}
require 'omf_web'
OMF::Web.start(opts)
