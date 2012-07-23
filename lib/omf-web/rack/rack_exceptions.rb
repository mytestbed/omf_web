
module OMF::Web::Rack
      
  class MissingArgumentException < Exception; end
  
  class RedirectException
    
    attr_reader :redirect_ulr
    
    def initialize(redirect_url)
      @redirect_url = redirect_url
    end
  end

end
