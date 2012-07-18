
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
    
    # Load content described by either a hash or a straightforward url
    # and return a 'ContentProxy' holding it.
    #
    # @return: Content proxy
    #
    def create_content_proxy_for(url_or_descr)
      if url_or_descr.is_a? String
        url = url_or_descr.to_s
        # descr = @descriptions[url]
        # unless descr
          # throw "Unknown content source '#{url}' (#{@@contents.keys.inspect})"
        # end
      elsif url_or_descr.is_a? Hash
        descr = url_or_descr
        unless url = descr[:url] || descr[:path]
          raise "Missing url in content description (#{descr.inspect})"
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
      opts = descr ? descr.dup : {}
      opts[:url] = url      
      opts[:url_key] = key
      opts[:name] = url # Should be something human digestable
      proxy = ContentProxy.new(url, self, opts)
      return proxy
    end
        
    def add_and_commit(file_name, message, req)
      Dir.chdir(@top_dir) do
        @repo.add(file_name)
        # TODO: Should set info about committing user which should be in 'req'
        @repo.commit_index(message || 'no message') 
      end
    end
    
    def read(url)
      file_name = url.split(':')[-1] # Should check if this is really this repository
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