
#require 'base64'
require 'grit'
require 'find'
require 'omf_common/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'

module OMF::Web

  # This class provides an interface to a GIT repository
  # It retrieves, archives and versions content.
  #
  class GitContentRepository < ContentRepository    
    
    def self.read_content(url, opts)
      unless (a = url.split(':')).length == 3
        raise "Expected 'git:some_name:some_path', but got '#{url}'"
      end
      git, name, path = a
      unless (repo = @@repositories['git:' + name])
        raise "Unknown git repository '#{name}'"
      end
      repo.read(path)
    end

    attr_reader :name, :top_dir
    
    def initialize(name, top_dir)
      @name = name
      @top_dir = top_dir
      @repo = Grit::Repo.new(top_dir)
      @url_prefix = "git:#{name}:"
      @@repositories['git:foo'] = self
    end
    
    #
    # Create a URL for a file with 'path' in.
    # If 'strictly_new' is true, returns nil if 'path' already exists.
    #
    def create_url(path, strictly_new = true)
      return "git:"
      # TODO: Need to add code to select proper repository
      return GitContentRepository.create_url(path, strictly_new)
    end
    
    
    # Load content described by either a hash or a straightforward path
    # and return a 'ContentProxy' holding it.
    #
    # If descr[:strictly_new] is true, return nil if file for which proxy is requested
    # already exists.
    #
    # @return: Content proxy
    #
    def create_content_proxy_for(path_or_descr)
      if path_or_descr.is_a? String
        path = path_or_descr.to_s
      elsif path_or_descr.is_a? Hash
        descr = path_or_descr
        unless path = descr[:path]
          raise "Missing 'path' in content description (#{descr.inspect})"
        end
        path = path.to_s
      else
        raise "Unsupported type '#{path_or_descr.class}'"
      end
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
      unless file_name = content_descr[:path]
        raise "Missing property 'path' in content descriptor '#{content_descr.inspect}'"
      end
      Dir.chdir(@top_dir) do
        unless File.writable?(file_name)
          raise "Cannot write to file '#{file_name}'"
        end
        f = File.open(file_name, 'w')
        f.write(content)
        f.close
        
        @repo.add(file_name)
        # TODO: Should set info about committing user which should be in thread context
        @repo.commit_index(message || 'no message') 
      end
    end
    
    def read(content_descr)
      unless file_name = content_descr[:path]
        raise "Missing property 'path' in content descriptor '#{content_descr.inspect}'"
      end
      Dir.chdir(@top_dir) do
        unless File.readable?(file_name)
          raise "Cannot read file '#{file_name}'"
        end
        content = File.open(file_name).read
        return content
      end
    end
    
    
    #
    # Return an array of file names which are in the repository and
    # match 'search_pattern'
    #
    def find_files(search_pattern)
      search_pattern = Regexp.new(search_pattern)
      tree = @repo.tree
      res = []
      _find_files(search_pattern, tree, nil, res)
    end
    
    def _find_files(search_pattern, tree, dir_path, res)
      tree.contents.each do |e|
        d = e.name
        long_name = dir_path ? "#{dir_path}/#{d}" : d

        if e.is_a? Grit::Tree
          _find_files(search_pattern, e, long_name, res)
        else
          if long_name.match(search_pattern)
            mt = mime_type_for_file(e.name)
            path = @url_prefix + long_name
            res << {:path => path, :name => e.name,
                    :mime_type => mt,
                    #:id => Base64.encode64(long_name).gsub("\n", ''), 
                    :size => e.size, :blob => e.id}
          end
          # name = e.name
          # if File.fnmatch(search_pattern, long_name)
            # res << long_name
          # end
        end
      end
      res
    end
              
  end # class
end # module