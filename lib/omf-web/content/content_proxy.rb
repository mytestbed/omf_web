
require 'digest/md5'
require 'omf_base/lobject'
require 'omf_web'

module OMF::Web

  # TODO: Is this really the right description???
  #
  # This object maintains synchronization between a JS DataSource object
  # in a web browser and the corresponding +OmlTable+ in this server.
  #
  #
  class ContentProxy < OMF::Base::LObject

    def self.[](key)
      #key = Digest::MD5.hexdigest(url)
      OMF::Web::SessionStore[key, :content_proxy]
    end

    # content_descriptor: url, mime_type, name
    def self.create(content_descr, repo)
      unless url = content_descr[:url]
        raise "Missing ':url' in content descriptor '#{content_descr.inspect}'"
      end
      key = Digest::MD5.hexdigest(url)

      if proxy = OMF::Web::SessionStore[key, :content_proxy]
        return proxy
      end
      debug "Create content proxy for '#{url}' (#{content_descr.inspect})"
      self.new(key, content_descr, repo)
    end

    attr_reader :content_descriptor, :content_url, :name, :mime_type, :repository

    def on_get(req)
      c = content()
      [c.to_s, "text"]
    end

    def on_post(req)
      data = req.POST
      write(data['content'], data['message'])
      [true.to_json, "text/json"]
    end

    def write(content, message = "")
      if content != @content
        debug "Updating '#{@content_descriptor.inspect}'"
        @content = content
        @repository.write(@content_descriptor, content, message)
      end
    end

    def content()
      unless @content
        @content = @repository.read(@content_descriptor)
      end
      @content
    end
    alias :read :content

    # Return a new proxy for a url relative to this one
    def create_proxy_for_url(url)
      unless url.match ':'
        unless url.start_with? '/'
          # relative
          ap = @repository.path(@content_descriptor)
          url = File.join(File.dirname(ap), url)
        end
        url = @repository.get_url_for_path(url)
      end
      @repository.create_content_proxy_for(url)
    end

    def read_only?
      @repository.read_only?
    end

    def to_s
      "\#<#{self.class} - #@name>"
    end

    private

    def initialize(key, content_descriptor, repository)
      @key = key
      @content_descriptor = content_descriptor
      @repository = repository
      #@path = File.join(repository.top_dir, content_handle) # requires 1.9 File.absolute_path(@content_handle, @repository.top_dir)

      #@content_id = content_descriptor[:url_key]
      @content_url = "/_content/#{key}"  # That most likley should come from the content handler

      @mime_type = @content_descriptor[:mime_type] ||= repository.mime_type_for_file(content_descriptor)
      @name = content_descriptor[:name]

      OMF::Web::SessionStore[key, :content_proxy] = self
      #@@proxies[@content_id] = self
    end

  end

end
