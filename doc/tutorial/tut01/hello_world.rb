
site_description = {
  id: 'top',
  top_level: true,
  type: 'layout/one_column',
  widgets: [
    name: "Welcome",
    type: 'text',
    content: {text: 'Hello World'}
  ]
}



# Configure the web server
#
opts = {
  :app_name => 'tut01',
  :page_title => 'Tutorial01: Hello World'
}

require 'omf_common/lobject'
OMF::Common::Loggable.init_log 'tut01'

require 'omf_web'
OMF::Web.register_widget(site_description)
OMF::Web.start(opts)
