
#require 'base64'
require 'grit'
require 'find'
require 'omf_common/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'

module OMF::Web

  # This class provides an interface to a particular content repository.
  # It retrieves, archives and versions content.
  #
  class ContentRepository < OMF::Common::LObject
    
    MIME_TYPE = {
      :js => 'text/javascript',       
      :md => 'text/markup',
      :rb => 'text/ruby',       
      :r => 'text/r',       
      :svg => 'text/svg',       
      :txt => 'text' 
    }
    
    # Repo to be used for all newly created content
    @@primary_repository = nil
     
    # Load content described by either a hash or a straightforward url
    # and return a 'ContentProxy' holding it.
    #
    # @return: Content proxy
    #
    def self.create_content_proxy_for(url_or_descr, opts = {})
      debug "self.create_content_proxy_for: '#{url_or_descr.inspect}'"
      if url_or_descr.is_a? ContentProxy
        return url_or_descr
      end
      
      if url_or_descr.is_a? String
        url = url_or_descr
      else
        if (text = url_or_descr[:text])
          # a bit of a hack for small static text blocks
          # Much better for maintenance is to use a separate file
          url = "static:-"
        else
          url = url_or_descr[:url]
        end
      end
      unless url
        throw "Can't find url in '#{url_or_descr.inspect}"
      end
      
      repo = find_repo_for(url)
      repo.create_content_proxy_for(url_or_descr)
    end
    
    def self.find_repo_for(url)
      parts = url.split(':')
      case type = parts[0]
      when 'git'
        require 'omf-web/content/git_repository' 
        return GitContentRepository[parts[1]]
      when 'file'
        require 'omf-web/content/file_repository' 
        return FileContentRepository[parts[1]]
      when 'static'
        require 'omf-web/content/static_repository' 
        return StaticContentRepository.instance
      else
        raise "Unknown repo type '#{type}'"
      end
    end
    
    def self.absolute_path_for(url)
      find_repo_for(url).absolute_path(url)
    end
    
    def self.read_content(url, opts)
      find_repo_for(url).read(url)
    end
    
    # Find files whose file name matches 'selector'. 
    # 
    # Supported options:
    #   * :max - Maximum numbers of matches to return
    #   * :mime_type - Only return files with that specific mime type.
    #
    def self.find_files(selector, opts = {})
      # TODO: Search across ALL registered repos
      fs = @@primary_repository.find_files(selector, opts)
      if (max = opts[:max])
        fs = fs[0, max]
      end
      fs
    end    
    
    #
    # Create a URL for a file with 'path' in the user's primary repository.
    # If 'strictly_new' is true, returns nil if 'path' already exists.
    #
    def self.create_url(path, strictly_new = true)
      # TODO: Need to add code to select proper repository
      return GitContentRepository.create_url(path, strictly_new)
    end
    
    

    attr_reader :top_dir
    
    def initialize(top_dir)
      @top_dir = top_dir
      @repo = Grit::Repo.new(top_dir)
    end
    
    
    def mime_type_for_file(content_descriptor)
      fname = content_descriptor[:path]
      ext = fname.split('.')[-1]
      mt = MIME_TYPE[ext.to_sym] || 'text'
    end
    
    def read(content_descr)
      path = _get_path(content_descr)
      Dir.chdir(@top_dir) do
        unless File.readable?(path)
          raise "Cannot read file '#{path}'"
        end
        content = File.open(path).read
        return content
      end
    end    
    
    def absolute_path(content_descr)
      path = _get_path(content_descr)
      File.join(@top_dir, path)
    end
    
    def path(content_descr)
      path = _get_path(content_descr)
    end
    
    # Return a URL for a path in this repo
    # 
    def get_url_for_path(path)
      raise "Missing implementation"
    end
  end # class
end # module