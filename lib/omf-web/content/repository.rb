
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
        url = url_or_descr[:url]
      end
      unless url
        throw "Can't find url in '#{url_or_descr.inspect}"
      end
      
      repo = find_repo_for(url)
      repo.create_content_proxy_for(url_or_descr)
    end
    
    def self.find_repo_for(url)
      parts = url.split(':')
      if (type = parts[0]) == 'git'
        require 'omf-web/content/git_repository' 
        return GitContentRepository[parts[1]]
      else
        raise "Unknown repo type '#{type}'"
      end
    end
    
    def self.read_content(url, opts)
      find_repo_for(url).read_content(url, opts)
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
    
    
    def mime_type_for_file(fname)
      ext = fname.split('.')[-1]
      mt = MIME_TYPE[ext.to_sym] || 'text'
    end
    
          
  end # class
end # module