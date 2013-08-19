
require 'omf_common/lobject'
require 'rack/accept'

use ::Rack::ShowExceptions
#use ::Rack::Lint
use Rack::Accept

OMF::Web::Runner.instance.life_cycle(:pre_rackup)
options = OMF::Web::Runner.instance.options
auth_opts = options[:authentication] || {required: false}

require 'omf-web/rack/session_authenticator'
use OMF::Web::Rack::SessionAuthenticator, #:expire_after => 10,
          login_page_url: auth_opts[:required] ? (auth_opts[:login_url] || '/content/login') : nil,
          no_session: ['^/resource/', '^/auth']

map "/resource/vendor/" do
  require 'omf-web/rack/multi_file'
  run OMF::Web::Rack::MultiFile.new(options[:static_dirs], :sub_path => 'vendor', :version => true)
end


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

map '/auth/login' do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    accept = env['rack-accept.request']
    begin
      OMF::Web::Rack::SessionAuthenticator.authenticate_with(req)
    rescue OMF::Web::Rack::AuthenticationFailedException => ax
      if accept.media_type?('application/json')
        body = {authenticated: false, message: ax.to_s}
        next [200, {"Content-Type" => "application/json"}, body.to_json]
      else
        url = auth_opts[:login_url] || '/content/login'
        url = "#{url}?error=#{URI.encode ax.to_s}"
        next [307, {'Location' => url, "Content-Type" => ""}, ['Next window!']]
      end
    end

    accept = env['rack-accept.request']
    redirect_url = "/?#{rand(10e15)}"  # avoid some ugly URL caching
    if accept.media_type?('application/json')
      body = {authenticated: true, redirect: redirect_url}
      [200, {"Content-Type" => "application/json"}, body.to_json]
    else
      [307, {'Location' => redirect_url, "Content-Type" => ""}, ['Next window!']]
    end
  end
  run handler
end

map '/auth/logout' do
  handler = Proc.new do |env|
    OMF::Web::Rack::SessionAuthenticator.logout

    accept = env['rack-accept.request']
    redirect_url = "/?#{rand(10e15)}"  # avoid some ugly URL caching
    if accept.media_type?('application/json')
      body = {authenticated: false, redirect: redirect_url}
      [200, {"Content-Type" => "application/json"}, body.to_json]
    else
      [307, {'Location' => redirect_url, "Content-Type" => ""}, ['Next window!']]
    end
  end
  run handler
end

map "/" do
  handler = Proc.new do |env|
    req = ::Rack::Request.new(env)
    case req.path_info
    when '/'
      [307, {'Location' => '/tab', "Content-Type" => ""}, ['Next window!']]
    when '/favicon.ico'
      [307, {'Location' => '/resource/image/favicon.ico', "Content-Type" => ""}, ['Next window!']]
    else
      OMF::Common::Loggable.logger('rack').warn "Can't handle request '#{req.path_info}'"
      [401, {"Content-Type" => ""}, "Sorry!"]
    end
  end
  run handler
end

OMF::Web::Runner.instance.life_cycle(:post_rackup)



