
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'simple'


require 'omf_oml/table'

def load_environment
  require 'omf-web/content/file_repository'
  

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
end


# Configure the web server
#
opts = {
  :app_name => 'ov_demo',
  :page_title => 'Dynamic Routing',
  :handlers => {
    # delay connecting to databases to AFTER we may run as daemon
    :pre_rackup => lambda { load_environment },
  }
}
require 'omf_web'
OMF::Web.start(opts)
