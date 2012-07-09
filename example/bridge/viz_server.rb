
#require 'omf-common/mobject2'
require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'bridge'
require 'omf-oml/table'

Dir.glob("#{File.dirname(__FILE__)}/data_sources/*.rb").each do |fn|
  load fn
end

require 'yaml'
Dir.glob("#{File.dirname(__FILE__)}/*.yaml").each do |fn|
  h = YAML.load_file(fn)
  if w = h['widget']
    OMF::Web.register_widget w
  # elsif t = h['tab']
    # OMF::Web.register_tab t
    # OMF::Web.use_tab t['id']
  else
    LObject.error "Don't know what to do with '#{fn}'"
  end
end


# Configure the web server
#
opts = {
  :page_title => 'Sydney Harbor Bridge Monitoring',
  #:use_tabs => [:graph]
  # :tabs => {
    # :foo => {:name => 'Foo', :order => 1, :class => Foo},
    # :goo => {:name => 'Goo', :order => 3}
  # }
}
require 'omf_web'
OMF::Web.start(opts)
