require 'rack/auth/abstract/handler'
require 'rack/auth/abstract/request'

module Rack
  module Auth
    # Rack::Auth::Basic implements HTTP Basic Authentication, as per RFC 2617.
    #
    # Initialize with the Rack application that you want protecting,
    # and a block that checks if a username and password pair are valid.
    #
    # See also: <tt>example/protectedlobster.rb</tt>

    class Basic < AbstractHandler
      

      def initialize(app, realm = nil, url_only = nil, &authenticator)
        super app, realm, &authenticator
        @url_only = url_only # only check those urls
      end
      

      def call(env)
        if @url_only
          path_info = env["PATH_INFO"]
          u = @url_only.find do |u|
            path_info.start_with?(u)
          end
          if u.nil?
            return @app.call(env)
          end
        end

        auth = Basic::Request.new(env)
        #puts ">>>> CHECKING #{env["PATH_INFO"]}" 
        return unauthorized unless auth.provided?

        return bad_request unless auth.basic?

        if valid?(auth)
          env['REMOTE_USER'] = auth.username

          return @app.call(env)
        end

        unauthorized
      end


      private

      def challenge
        'Basic realm="%s"' % realm
      end

      def valid?(auth)
        @authenticator.call(*auth.credentials)
      end

      class Request < Auth::AbstractRequest
        def basic?
          :basic == scheme
        end

        def credentials
          @credentials ||= params.unpack("m*").first.split(/:/, 2)
        end

        def username
          credentials.first
        end
      end

    end
  end
end