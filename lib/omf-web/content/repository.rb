
require 'base64'
require 'grit'
require 'find'
require 'omf_common/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'

module OMF::Web

  # This class provides an interface to a particular content repository.
  # It retrieves, archives and versions content.
  #
  class ContentRepository
    
    MIME_TYPE = {
      :js => 'text/javascript',       
      :md => 'text/markup',
      :rb => 'text/ruby',       
      :r => 'text/r',       
      :svg => 'text/svg',       
      :txt => 'text' 
    }
    
    @@repositories = {}
    
    # Return the repository which is referenced to by elements in 'opts'.
    #
    #
    def self.[](opts)
      # TODO: HACK ALERT
      unless repo = @@repositories[:default]
        repo = @@repositories[:default] = self.new('/tmp/foo')
        #repo = @@repositories[:default] = self.new('.')
      end
      repo
    end

    attr_reader :top_dir
    
    def initialize(top_dir)
      @top_dir = top_dir
      @repo = Grit::Repo.new(top_dir)
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
      opts = descr.dup
      opts[:url] = url      
      opts[:url_key] = key
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
            res << {:path => long_name, :name => e.name,
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
    
    def mime_type_for_file(fname)
      ext = fname.split('.')[-1]
      mt = MIME_TYPE[ext.to_sym] || 'text'
    end
    
          
  end # class
end # module