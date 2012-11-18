
#require 'omf-common/mobject2'
require 'omf_common/lobject'
# require 'yaml'
# require 'log4r'

#OMF::Common::Loggable.init_log 'bridge', 'development', :searchPath => File.dirname(__FILE__)
OMF::Common::Loggable.init_log 'bridge', :searchPath => File.dirname(__FILE__)


# If set, create fake sensor events 
$fake_bridge_events = false
# Path to OML database
$oml_database = 'sqlite://example/bridge/data_sources/test3.sq3'

require 'omf_oml/table'

def load_environment

  Dir.glob("#{File.dirname(__FILE__)}/data_sources/*.rb").each do |fn|
    load fn
  end
  
  require 'yaml'
  Dir.glob("#{File.dirname(__FILE__)}/widgets/*.yaml").each do |fn|
    OMF::Common::LObject.debug "Load yaml file '#{fn}'"
    h = YAML.load_file(fn)
    if w = h['widget']
      OMF::Web.register_widget w
    else
      OMF::Common::LObject.error "Don't know what to do with '#{fn}'"
    end
  end
end


# Configure the web server
#
opts = {
  :app_name => 'bridge',
  :page_title => 'Sydney Harbour Bridge Monitoring',
  :footer_left => lambda do |e|
    #img :src => '/resource/image/imagined_by_nicta.jpeg', :height => 24
    text 'Imagined by NICTA'
  end,
  :footer_right => 'git:omf_web/bridge',
  :static_dirs_pre => ["#{File.dirname(__FILE__)}/htdocs"],
  :handlers => {
    # delay connecting to databases to AFTER we may run as daemon
    :pre_rackup => lambda { load_environment },
    :pre_parse => lambda do |p|
      p.separator ""
      p.separator "BRIDGE options:"
      p.on("--fake-events", "If set, create fake sensor events") { $fake_bridge_events = true }
      p.on("--oml-database DATABASE", "Database containing bridge data [#{$oml_database}]") do |f|
        $oml_database = f
      end
      p.separator ""
    end
  }
}
require 'omf_web'
OMF::Web.start(opts)
