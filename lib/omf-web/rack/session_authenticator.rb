
require 'omf_common/lobject'
require 'rack'
require 'omf-web/session_store'


module OMF::Web::Rack
  class AuthenticationFailedException < Exception

  end

  # This rack module maintains a session cookie and
  # redirects any requests to protected pages to a
  # 'login' page at the beginning of a session
  #
  # Calls to the class methods are resolved inthe context
  # of a Session using 'OMF::Web::SessionStore'
  #
  class SessionAuthenticator < OMF::Common::LObject

    # Returns true if this Rack module has been instantiated
    # in the current Rack stack.
    #
    def self.active?
      @@active
    end

    # Return true if the session is authenticated
    #
    def self.authenticated?
      auth = self[:authenticated] == true && self[:valid_until] > Time.now
      #debug "AUTH: #{auth}"
      auth
    end

    # Calling this method will authenticate the current session
    #
    def self.authenticate(expires = nil)
      self[:authenticated] = true
      self[:valid_until] = Time.now + @@expire_after
    end

    # Information about the authenticated user
    #
    def self.user()
      self[:user]
    end

    # Attempt to authenticate with the provided 'req'
    def self.authenticate_with(req)
      p = req.params
      #puts ">>>>>>> AA(#{req.host_with_port}): #{p}"
      case t = p['method']
      when 'persona'
        require 'net/http'
        unless assertion = p['assertion']
          raise AuthenticationFailedException.new("Missing assertion")
        end

        http = Net::HTTP.new('verifier.login.persona.org', 443)
        http.use_ssl = true
        data = "assertion=#{assertion}&audience=#{req.host_with_port}"
        headers = {'Content-Type' => 'application/x-www-form-urlencoded'}
        reply = http.post('/verify', data, headers)
        unless reply.code_type == Net::HTTPOK && reply.content_type == "application/json"
          raise AuthenticationFailedException.new("Could not verify Persona - '#{reply.body}'")
        end
        debug "Persona reply: '#{reply.body}'"
        r = JSON.load(reply.body)
        unless ((email = r['email']) && (expires = r['expires']))
          raise AuthenticationFailedException.new("Could not verify Persona - '#{r}'")
        end
        self[:user] = {name: email, email: email, method: 'persona'}
        authenticate(Time.at(expires))
      else
        raise AuthenticationFailedException.new("Unsupported authentication type '#{t}'")
      end
    end

    # Logging out will un-authenticate this session
    #
    def self.logout
      debug "LOGOUT"
      self[:authenticated] = false
      self[:user] = nil
    end

    # DO NOT CALL DIRECTLY
    #
    def self.[](key)
      OMF::Web::SessionStore[key, :authenticator]
    end

    # DO NOT CALL DIRECTLY
    #
    def self.[]=(key, value)
      OMF::Web::SessionStore[key, :authenticator] = value
    end

    @@active = false
    # Expire authenticated session after being idle for that many seconds
    @@expire_after = 2592000

    #
    # opts -
    #   :login_url - URL to redirect if session is not authenticated
    #   :no_session - Array of regexp on 'path_info' which do not require an authenticated session
    #   :expire_after - Idle time in sec after which to expire a session
    #
    def initialize(app, opts = {})
      @app = app
      @opts = opts
      @opts[:no_session] = (@opts[:no_session] || []).map { |s| Regexp.new(s) }
      if @opts[:expire_after]
        @@expire_after = @opts[:expire_after]
      end
      @@active = true
    end

    def check_authenticated
      authenticated = self.class.authenticated?
      raise AuthenticationFailedException.new unless authenticated
    end

    def call(env)
      req = ::Rack::Request.new(env)
      path_info = req.path_info
      sid = req.cookies['sid']
      unless sid
        sid = "s#{(rand * 10000000).to_i}_#{(rand * 10000000).to_i}"
      end
      Thread.current["sessionID"] = sid  # needed for Session Store
      debug "Request for '#{path_info}' - sid: #{sid} - #{self.class.authenticated?}"
      unless @opts[:no_session].find {|rx| rx.match(path_info) }
        # If 'login_page_url' is defined, check if this session is authenticated
        login_url = @opts[:login_page_url]
        if login_url && login_url != req.path_info
          begin
            check_authenticated
          rescue AuthenticationFailedException => ex
            if err = self.class[:login_error]
              login_url = login_url + "?msg=#{err}"
            end
            headers = {'Location' => login_url, "Content-Type" => ""}
            Rack::Utils.set_cookie_header!(headers, 'sid', sid)
            return [307, headers, ['Login first']]
          end
        end
      end

      status, headers, body = @app.call(env)
      Rack::Utils.set_cookie_header!(headers, 'sid', sid) # if sid
      [status, headers, body]
    end
  end # class

end # module




