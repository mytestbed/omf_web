
#require 'omf-common/mobject2'
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'bridge'
require 'omf-oml/table'

Dir.glob("#{File.dirname(__FILE__)}/data_sources/*.rb").each do |fn|
  load fn
end

require 'yaml'
Dir.glob("#{File.dirname(__FILE__)}/*.yaml").each do |fn|
  OMF::Common::LObject.debug "Load yaml file '#{fn}'"
  h = YAML.load_file(fn)
  if w = h['widget']
    OMF::Web.register_widget w
  # elsif t = h['tab']
    # OMF::Web.register_tab t
    # OMF::Web.use_tab t['id']
  else
    OMF::Common::LObject.error "Don't know what to do with '#{fn}'"
  end
end


# Configure the web server
#
opts = {
  :page_title => 'Sydney Harbor Bridge Monitoring',
  :static_dirs_pre => ["#{File.dirname(__FILE__)}/htdocs"]
}
require 'omf_web'
OMF::Web.start(opts)
