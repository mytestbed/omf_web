
module OMF::Web::Rack
      
  class MissingArgumentException < Exception; end
  
  class RedirectException < Exception
    
    attr_reader :redirect_url
    
    def initialize(redirect_url)
      @redirect_url = redirect_url
    end
  end

end
