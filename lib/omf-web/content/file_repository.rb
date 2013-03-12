
require 'find'
require 'omf_common/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'

module OMF::Web

  # This class provides an interface to a directory based repository
  # It retrieves, archives and versions content.
  #
  class FileContentRepository < ContentRepository  
    
    # @@file_repositories = {}
#     
    # # Return the repository which is referenced to by elements in 'opts'.
    # #
    # #
    # def self.[](name)
      # unless repo = @@file_repositories[name.to_sym]
        # raise "Unknown file repo '#{name}'"
      # end
      # repo
    # end
#       
    # # Register an existing directory to the system. It will be 
    # # consulted for all content url's strarting with
    # # 'file:_top_dir_:'. If 'is_primary' is set to true, it will
    # # become the default repo for all newly created content
    # # in this app.
    # #
    # def self.register_file_repo(name, top_dir, is_primary = false)
      # name = name.to_sym
      # if @@file_repositories[name]
        # warn "Ignoring repeated registration of file rep '#{name}'"
        # return
      # end
      # repo = @@file_repositories[name] = FileContentRepository.new(name, top_dir)
      # if is_primary
        # @@primary_repository = repo
      # end
    # end
    
    
    def initialize(name, opts)
      super
      @url_prefix = "file:#{name}:"
    end
    
    #
    # Create a URL for a file with 'path' in.
    # If 'strictly_new' is true, returns nil if 'path' already exists.
    #
    # def create_url(path, strictly_new = true)
      # return "git:"
      # # TODO: Need to add code to select proper repository
      # return GitContentRepository.create_url(path, strictly_new)
    # end
    
    
    # Load content described by either a hash or a straightforward path
    # and return a 'ContentProxy' holding it.
    #
    # If descr[:strictly_new] is true, return nil if file for which proxy is requested
    # already exists.
    #
    # @return: Content proxy
    #
    def create_content_proxy_for(content_descr)
      path = _get_path(content_descr)
      # TODO: Make sure that key is really unique across multiple repositories
      descr = descr ? descr.dup : {}
      url = @url_prefix + path
      key = Digest::MD5.hexdigest(url)
      descr[:url] = url      
      descr[:url_key] = key
      descr[:path] = path      
      descr[:name] = url # Should be something human digestable
      if (descr[:strictly_new])
        Dir.chdir(@top_dir) do
          return nil if File.exist?(path)
        end
      end
      proxy = ContentProxy.create(descr, self)
      return proxy
    end
        
    def write(content_descr, content, message)
      path = _get_path(content_descr)
      Dir.chdir(@top_dir) do
        unless File.writable?(path)
          raise "Cannot write to file '#{path}'"
        end
        f = File.open(path, 'w')
        f.write(content)
        f.close
      end
    end
    
    # Return a URL for a path in this repo
    # 
    def get_url_for_path(path)
      "file:#{path}"
    end
    
    def _get_path(content_descr)
      if content_descr.is_a? String
        path = content_descr.to_s
        if path.start_with? 'file:'
          path = path.split(':')[2]
        end
      elsif content_descr.is_a? Hash
        descr = content_descr
        if (url = descr[:url])
          path = url.split(':')[2] # git:repo_name:path
        else
          path = descr[:path]
        end
        unless path
          raise "Missing 'path' or 'url' in content description (#{descr.inspect})"
        end
        path = path.to_s
      else
        raise "Unsupported type '#{content_descr.class}'"
      end
      unless path
        raise "Can't find path information in '#{content_descr.inspect}'"
      end
      return path
    end
              
  end # class
end # module