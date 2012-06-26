
require 'omf_common/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'

module OMF::Web

  # This class provides an interface to a particular content repository.
  # It retrieves, archives and versions content.
  #
  class ContentRepository
    
    @@repositories = {}
    
    # Return the repository which is referenced to by elements in 'opts'.
    #
    #
    def self.[](opts)
      # TODO: HACK ALERT
      unless repo = @@repositories[:default]
        #@@repositories[:default] = self.new('/tmp/foo')
        repo = @@repositories[:default] = self.new('.')
      end
      repo
    end

    attr_reader :top_dir
    
    def initialize(top_dir)
      @top_dir = top_dir
    end
    
    # Load content described by either a hash or a straightforward url
    # and return a 'ContentProxy' holding it.
    #
    # @return: Content proxy
    #
    def load(url_or_descr)
      if url_or_descr.is_a? String
        url = url_or_descr.to_s
        descr = @descriptions[url]
        unless descr
          throw "Unknown content source '#{url}' (#{@@contents.keys.inspect})"
        end
      elsif url_or_descr.is_a? Hash
        descr = url_or_descr
        unless url = descr[:url]
          raise "Missing url in content description (#{content_description.inspect})"
        end
        url = url.to_s
      else
        raise "Unsupported type '#{url_or_descr.class}'"
      end
      # TODO: Make sure that key is really unique across multiple repositories
      key = Digest::MD5.hexdigest(url)
      if proxy = ContentProxy[key]
        return proxy
      end
      opts = descr.dup
      opts[:url] = url      
      opts[:url_key] = key
      proxy = ContentProxy.new(url, self, opts)
      return proxy
    end
    
      
  end # class
end # module