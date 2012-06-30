
require 'digest/md5'
require 'omf_common/lobject'
require 'omf_web'

module OMF::Web
        
  # This object maintains synchronization between a JS DataSource object 
  # in a web browser and the corresponding +OmlTable+ in this server.
  #
  #
  class ContentProxy < OMF::Common::LObject
    
    # @@descriptions = {}
    @@proxies = {}

    def self.[](url)
      @@proxies[url.to_s]
    end
#     
    # def self.register_content(content_description, opts = {})
      # descr = OMF::Web.deep_symbolize_keys(content_description)
      # unless url = descr[:url]
        # raise "Missing url in content description (#{content_description.inspect})"
      # end
      # url = url.to_s
      # if (@@descriptions.key? url)
        # raise "Repeated try to register content source '#{url}'"
      # end
      # @@descriptions[url] = descr
      # url
    # end
#     
    # # Return proxies for 'url'. This proxy is only valid within this session
    # #
    # # @return: Content proxies
    # #
    # def self.create_proxy(url_or_descr)
      # if url_or_descr.is_a? String
        # url = url_or_descr.to_s
        # descr = @@descriptions[url]
        # unless descr
          # throw "Unknown content source '#{url}' (#{@@contents.keys.inspect})"
        # end
      # elsif url_or_descr.is_a? Hash
        # descr = url_or_descr
        # unless url = descr[:url]
          # raise "Missing url in content description (#{content_description.inspect})"
        # end
        # url = url.to_s
      # else
        # raise "Unsupported type '#{url_or_descr.class}'"
      # end
      # key = descr[:url_key] ||= Digest::MD5.hexdigest(url) 
      # proxy = @@proxies[key] ||= self.new(url, descr)
      # return proxy
    # end
#     
    
    attr_reader :content_url, :content_id
    
    def initialize(file_name, repository, opts)
      @file_name = file_name
      @repository = repository
      @path = File.join(repository.top_dir, file_name) # requires 1.9 File.absolute_path(@file_name, @repository.top_dir)
      
      @opts = opts
      @version = 0 # TODO: GET right version      
      
      @content_id = opts[:url_key]
      @content_url = "/_content/#{@content_id}?v=#{@version}"

      @@proxies[@content_id] = self
    end
    
    def on_get(req)
      c = content()
      [c.to_s, "text"]
    end
    
    def on_post(req)
      data = req.POST
      if (content = data['content']) != @content
        @content = content
        unless File.writable?(@path)
          raise "Cannot write to file '#{@path}'"
        end
        f = File.open(@path, 'w')
        f.write(content)
        f.close
        @repository.add_and_commit(@file_name, data['message'], req)
       
      end
      [true.to_json, "text/json"]
    end

    def content()
      unless @content
        unless File.readable?(@path)
          raise "Cannot read file '#{@path}'"
        end
        @content = File.open(@path).read
      end
      @content
    end
    
    
    
  end
  
end
