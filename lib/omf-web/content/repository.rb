
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
        require 'omf-web/content/git_repository'
        @@repositories[:default] = GitContentRepository.new(:foo, '/tmp/foo')
      end
      repo
    end
    
    # Load content described by either a hash or a straightforward url
    # and return a 'ContentProxy' holding it.
    #
    # @return: Content proxy
    #
    def self.create_content_proxy_for(url_or_descr, opts = {})
      if url_or_descr.is_a? ContentProxy
        return url_or_descr
      end
      
      unless repo = self[opts]
        throw "Can't find appropriate respository"
      end
      
      repo.create_content_proxy_for(url_or_descr)
    end
    
    def self.read_content(url, opts)
      case (type = url.split(':')[0])
      when 'git'
        return GitContentRepository.read_content(url, opts)
      else
        raise "Unknown repository type '#{type}'"
      end
    end
    

    attr_reader :top_dir
    
    def initialize(top_dir)
      @top_dir = top_dir
      @repo = Grit::Repo.new(top_dir)
    end
    
    # # Load content described by either a hash or a straightforward url
    # # and return a 'ContentProxy' holding it.
    # #
    # # @return: Content proxy
    # #
    # def create_content_proxy_for(url_or_descr)
      # if url_or_descr.is_a? String
        # url = url_or_descr.to_s
        # # descr = @descriptions[url]
        # # unless descr
          # # throw "Unknown content source '#{url}' (#{@@contents.keys.inspect})"
        # # end
      # elsif url_or_descr.is_a? Hash
        # descr = url_or_descr
        # unless url = descr[:url] || descr[:path]
          # raise "Missing url in content description (#{descr.inspect})"
        # end
        # url = url.to_s
      # else
        # raise "Unsupported type '#{url_or_descr.class}'"
      # end
      # # TODO: Make sure that key is really unique across multiple repositories
      # key = Digest::MD5.hexdigest(url)
      # if proxy = ContentProxy[key]
        # return proxy
      # end
      # opts = descr ? descr.dup : {}
      # opts[:url] = url      
      # opts[:url_key] = key
      # proxy = ContentProxy.new(url, self, opts)
      # return proxy
    # end
#     
    # def add_and_commit(file_name, message, req)
      # Dir.chdir(@top_dir) do
        # @repo.add(file_name)
        # # TODO: Should set info about committing user which should be in 'req'
        # @repo.commit_index(message || 'no message') 
      # end
    # end
#     
    # def read(file_name)
      # Dir.chdir(@top_dir) do
        # unless File.readable?(file_name)
          # raise "Cannot read file '#{file_name}'"
        # end
        # content = File.open(file_name).read
        # return content
      # end
    # end
#     
#     
    # #
    # # Return an array of file names which are in the repository and
    # # match 'search_pattern'
    # #
    # def find_files(search_pattern)
      # search_pattern = Regexp.new(search_pattern)
      # tree = @repo.tree
      # res = []
      # _find_files(search_pattern, tree, nil, res)
    # end
#     
    # def _find_files(search_pattern, tree, dir_path, res)
      # tree.contents.each do |e|
        # d = e.name
        # long_name = dir_path ? "#{dir_path}/#{d}" : d
# 
        # if e.is_a? Grit::Tree
          # _find_files(search_pattern, e, long_name, res)
        # else
          # if long_name.match(search_pattern)
            # mt = mime_type_for_file(e.name)
            # path = "git:#{@top_dir}:#{long_name}"
            # res << {:path => path, :name => e.name,
                    # :mime_type => mt,
                    # #:id => Base64.encode64(long_name).gsub("\n", ''), 
                    # :size => e.size, :blob => e.id}
          # end
          # # name = e.name
          # # if File.fnmatch(search_pattern, long_name)
            # # res << long_name
          # # end
        # end
      # end
      # res
    # end
    
    def mime_type_for_file(fname)
      ext = fname.split('.')[-1]
      mt = MIME_TYPE[ext.to_sym] || 'text'
    end
    
          
  end # class
end # module