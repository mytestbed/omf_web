
require 'omf_common/lobject'
require 'omf-web/rack/rack_exceptions'
require 'omf-web/content/content_proxy'

module OMF::Web::Rack
      
  class ContentHandler < OMF::Common::LObject
    
    def call(env)
      req = ::Rack::Request.new(env)
      begin
        c_id = req.path_info[1 .. -1]
        c_proxy = OMF::Web::ContentProxy[c_id]
        unless c_proxy
          raise MissingArgumentException.new "Can't find content proxy '#{c_id}'"
        end
        method = "on_#{req.request_method().downcase}"
        body, headers = c_proxy.send(method.to_sym, req)
      rescue MissingArgumentException => mex
        debug mex
        return [412, {"Content-Type" => 'text'}, [mex.to_s]]
      rescue Exception => ex
        error ex
        debug ex.to_s + "\n\t" + ex.backtrace.join("\n\t")
        return [500, {"Content-Type" => 'text'}, [ex.to_s]]
      end
      
      if headers.kind_of? String
        headers = {"Content-Type" => headers}
      end
      [200, headers, [body]] 
    end
  end # ContentHandler
  
end # OMF:Web


      
        
