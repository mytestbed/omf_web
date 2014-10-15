
module OMF::Web::Rack

  class RackException < Exception
    attr_reader :reply

    def initialize(err_code, reason)
      super reason
      body = {:exception => {
        :code => err_code,
        :reason => reason
      }}
      @reply = [err_code, {"Content-Type" => 'text/json'}, body.to_json]
    end

  end

  class UnknownResourceException < RackException
    def initialize(reason)
      super 404, reason
    end
  end

  class MissingResourceException < RackException
    def initialize(reason)
      super 404, reason
    end
  end
      
  class MissingArgumentException < RackException
    def initialize(reason = '')
      super 412, reason
    end
  end
  
  class RedirectException < Exception
    
    attr_reader :redirect_url
    
    def initialize(redirect_url)
      @redirect_url = redirect_url
    end
  end

end
