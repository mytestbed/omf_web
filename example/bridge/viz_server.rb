
#require 'omf-common/mobject2'
require 'omf_common/lobject'
# require 'yaml'
# require 'log4r'

#OMF::Common::Loggable.init_log 'bridge', 'development', :searchPath => File.dirname(__FILE__)
OMF::Common::Loggable.init_log 'bridge', :searchPath => File.dirname(__FILE__)

    
require 'omf-oml/table'

def load_environment

  Dir.glob("#{File.dirname(__FILE__)}/data_sources/*.rb").each do |fn|
    load fn
  end
  
  require 'yaml'
  Dir.glob("#{File.dirname(__FILE__)}/*.yaml").each do |fn|
    next if fn.match /log4r.yaml/
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
  :page_title => 'Sydney Harbor Bridge Monitoring',
  :static_dirs_pre => ["#{File.dirname(__FILE__)}/htdocs"],
  :handlers => {
    :pre_rackup => lambda { load_environment }
  }
}
require 'omf_web'
OMF::Web.start(opts)
 # do 
  # load_environment
# end
