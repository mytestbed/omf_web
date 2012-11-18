
require 'omf_common/lobject'

use ::Rack::ShowExceptions
#use ::Rack::Lint

OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options

require 'omf-web/rack/session_authenticator'                               
use OMF::Web::Rack::SessionAuthenticator, #:expire_after => 10, 
          #:login_url => '/tab/login',
          :no_session => ['^/resource/', '^/login', '^/logout']


map "/resource" do
  require 'omf-web/rack/multi_file'
  run OMF::Web::Rack::MultiFile.new(options[:static_dirs])
end

map '/_ws' do
  begin
    require 'omf-web/rack/websocket_handler'
    run OMF::Web::Rack::WebsocketHandler.new #:backend => { :debug => true }
  rescue Exception => ex
    OMF::Common::Loggable.logger('web').error "#{ex}"
  end
end

map '/_update' do
  require 'omf-web/rack/update_handler'
  run OMF::Web::Rack::UpdateHandler.new
end

map '/_content' do
  require 'omf-web/rack/content_handler'
  run OMF::Web::Rack::ContentHandler.new
end

map "/tab" do
  require 'omf-web/rack/tab_mapper'
  run OMF::Web::Rack::TabMapper.new(options)
end

# map "/widget" do
  # require 'omf-web/rack/widget_mapper'
  # run OMF::Web::Rack::WidgetMapper.new(options)
# end

map '/login' do
  handler = Proc.new do |env| 
    # req = ::Rack::Request.new(env)
    # #puts ">>> post?: #{req.post?} - #{req.params.inspect}"
    # if req.post?
      # email = req.params["email"]
      # pw = req.params["password"]
      # remember = req.params["remember"] == "on"
      # Authenticator.signon(email, pw, remember)
    # end
    [301, {'Location' => '/tab', "Content-Type" => ""}, ['Next window!']]
  end
  run handler
end

map '/logout' do
  handler = Proc.new do |env| 
    OMF::Web::Rack::SessionAuthenticator.logout
    [301, {'Location' => '/tab', "Content-Type" => ""}, ['Next window!']]
  end
  run handler
end

map "/" do
  handler = Proc.new do |env| 
    req = ::Rack::Request.new(env)
    case req.path_info
    when '/'
      [301, {'Location' => '/tab', "Content-Type" => ""}, ['Next window!']]
    when '/favicon.ico'
      [301, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    else
      OMF::Common::Loggable.logger('rack').warn "Can't handle request '#{req.path_info}'"
      [401, {"Content-Type" => ""}, "Sorry!"]
    end 
  end
  run handler
end

OMF::Web::Runner.instance.life_cycle(:post_rackup)



