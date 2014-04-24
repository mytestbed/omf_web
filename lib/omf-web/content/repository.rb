
#require 'base64'
require 'grit'
require 'find'
require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'

module OMF::Web

  class ContentRepositoryException < Exception; end
  class ReadOnlyContentRepositoryException < ContentRepositoryException; end

  # This class provides an interface to a particular content repository.
  # It retrieves, archives and versions content.
  #
  class ContentRepository < OMF::Base::LObject

    MIME_TYPE = {
      :js => 'text/javascript',
      :md => 'text/markup',
      :rb => 'text/ruby',
      :oedl => 'text/ruby',
      :r => 'text/r',
      :svg => 'text/svg',
      :txt => 'text'
    }

    REPO_PLUGINS = {
      git: lambda do |name, opts|
              require 'omf-web/content/git_repository'
              return GitContentRepository.new(name, opts)
          end,
      file: lambda do |name, opts|
              require 'omf-web/content/file_repository'
              return FileContentRepository.new(name, opts)
          end,
      irods: lambda do |name, opts|
              require 'omf-web/content/irods_repository'
              return IRodsContentRepository.new(name, opts)
          end,
      static: lambda do |name, opts|
              require 'omf-web/content/static_repository'
              return StaticContentRepository.new(name, opts)
          end
    }

    # Repo to be used for all newly created content
    @@primary_repository = nil
    @@repositories = {}

    def self.register_repo(name, opts)
      raise "ArgumentMismatch: Expected Hash, but got #{opts}" unless opts.is_a? Hash

      name = name.to_sym
      if @@repositories[name]
        warn "Ignoring repeated registration of repo '#{name}'"
        return
      end

      unless type = opts[:type]
        raise "Missing type in repo opts (#{opts})"
      end
      unless repo_creator = REPO_PLUGINS[type.to_sym]
        raise "Unknown repository type '#{type}'"
      end
      @@repositories[name] = r = repo_creator.call(name, opts)
      @@primary_repository = r if opts[:is_primary]
      r
    end


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
          require 'omf-web/content/static_repository'
          url = OMF::Web::StaticContentRepository.create_from_text(url_or_descr, opts)
          #url = repo.url # "static:-"
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


    def self.absolute_path_for(url)
      find_repo_for(url).absolute_path(url)
    end

    def self.read_content(url, opts)
      find_repo_for(url).read(url)
    end

    def self.find_repo_for(url)
      parts = url.split(':')
      name = parts[1]
      unless repo = @@repositories[name.to_sym]
        raise "Unknown repo '#{name}'"
      end
      return repo
    end


    # Find files whose file name matches 'selector'.
    #
    # Supported options:
    #   * :max - Maximum numbers of matches to return
    #   * :mime_type - Only return files with that specific mime type.
    #   * :repo_iterator [Iterator] - Iterator over repos to search
    #
    def self.find_files(selector, opts = {})
      fsa = (opts[:repo_iterator] || [@@primary_repository]).map do |repo|
        repo.find_files(selector, opts)
      end

      fs = fsa.flatten
      if (mt = opts[:mime_type])
        fs = fs.select { |f| File.fnmatch(mt, f[:mime_type]) }
      end

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


    attr_reader :name, :top_dir

    # params opts [Hash]
    # opts read_only [Boolean] If true, write will fail
    def initialize(name, opts)
      @name = name
      @read_only = (opts[:read_only] == true)

      if @top_dir = opts[:top_dir]
        @top_dir = File.expand_path(@top_dir)
      end
    end

    #
    # Return an array of file names which are in the repository and
    # match 'search_pattern'
    #
    def find_files(search_pattern, opts = {})
      raise "Missing implementation"
    end

    # Return true if repo is read only. Any attempts to write to
    # a read only repo will result in a 'ReadOnlyContentRepositoryException'
    # exception.
    #
    def read_only?
      @read_only
    end

    def mime_type_for_file(content_descriptor)
      fname = content_descriptor
      if content_descriptor.is_a? Hash
        fname = content_descriptor[:path]
      end
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

    def write(content_descr, content, message)
      raise "Missing implementation"
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
