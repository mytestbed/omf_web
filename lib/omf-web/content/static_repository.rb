
require 'omf_common/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'
require 'singleton'

module OMF::Web
  
  # This class provides an interface to a repository of static,
  # preloaded content.
  #
  class StaticContentRepository < ContentRepository  
      
    
    # Load content described by either a hash or a straightforward path
    # and return a 'ContentProxy' holding it.
    #
    # @return: Content proxy
    #
    def create_content_proxy_for(content_descr)
      debug content_descr
      if content_descr.is_a? String
        content_descr = {text: content_descr}
      end
      descr = content_descr.dup
      unless text = descr.delete(:text)
        raise "Missing ':text' declaraton for static content"
      end
      
      key = Digest::MD5.hexdigest(text)
      @content[key] = text
      descr[:url] = url = "static:" + key
      descr[:url_key] = key
      descr[:name] = content_descr[:name] || url # Should be something human digestable
      proxy = ContentProxy.create(descr, self)
      return proxy
    end

    def read(content_descr)
      debug "READ: #{content_descr}"
      @content[content_descr[:url_key]] || 'Unknown'
    end
           
    def write(content_descr, content, message)
      raise "READ ONLY"
    end

    def mime_type_for_file(content_descriptor)
      content_descriptor[:mime_type] || 'text'
    end

    def initialize(name, opts)
      super
      @content = {}
    end
    
    
              
  end # class
end # module