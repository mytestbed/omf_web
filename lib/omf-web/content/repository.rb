
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
      git:
        lambda do |name, opts|
          require 'omf-web/content/git_repository'
          return GitContentRepository.new(name, opts)
        end,
      gitolite:
        lambda do |name, opts|
          require 'omf-web/content/gitolite_repository'
          return GitoliteContentRepository.new(name, opts)
        end,
      file:
        lambda do |name, opts|
          require 'omf-web/content/file_repository'
          return FileContentRepository.new(name, opts)
        end,
      irods:
        lambda do |name, opts|
          require 'omf-web/content/irods_repository'
          return IRodsContentRepository.new(name, opts)
        end,
      static:
        lambda do |name, opts|
          require 'omf-web/content/static_repository'
          return StaticContentRepository.new(name, opts)
        end
    }

    # Repo to be used for all newly created content
    @@primary_repository = nil
    @@repositories = {}

    # Prepand this path if 'top_dir' starts with '.'
    @@reference_dir = nil

    # Prepand this path if 'top_dir' starts with '.'
    def self.reference_dir=(dir)
      @@reference_dir = dir
    end

    def self.reference_dir
      @@reference_dir
    end

    def self.register_repo(name, opts)
      raise "ArgumentMismatch: Expected Hash, but got #{opts}" unless opts.is_a? Hash

      name = name.to_sym
      if @@repositories[name]
        warn "Ignoring repeated registration of repo '#{name}'"
        return
      end

      # unless type = opts[:type]
        # raise "Missing type in repo opts (#{opts})"
      # end
      # unless repo_creator = REPO_PLUGINS[type.to_sym]
        # raise "Unknown repository type '#{type}'"
      # end

      @@repositories[name] = r = create(name, opts)
      @@primary_repository = r if opts[:is_primary]
      r
    end

    def self.create(name, opts)
      raise "ArgumentMismatch: Expected Hash, but got #{opts}" unless opts.is_a? Hash

      unless type = opts[:type]
        raise "Missing type in repo opts (#{opts})"
      end
      unless repo_creator = REPO_PLUGINS[type.to_sym]
        raise "Unknown repository type '#{type}'"
      end
      r = repo_creator.call(name, opts)
    end



    # Load content described by either a hash or a straightforward url
    # and return a 'ContentProxy' holding it.
    #
    # @params
    #    - :repo_iterator: Iterator over available repos
    #
    # @return: Content proxy
    #
    def self.create_content_proxy_for(url_or_descr, opts = {})
      if url_or_descr.is_a? ContentProxy
        return url_or_descr
      end
      debug "self.create_content_proxy_for: '#{url_or_descr.inspect}'"

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

      repo = find_repo_for(url, opts)
      #puts ">>>>>> FOUND REPO: #{repo} for url #{url}"
      repo.create_content_proxy_for(url_or_descr)
    end


    def self.absolute_path_for(url)
      find_repo_for(url).absolute_path(url)
    end

    def self.read_content(url, opts)
      find_repo_for(url, opts).read(url)
    end

    def self.find_repo_for(url, opts = {})
      parts = url.split(':')
      name = (parts[parts.length == 2 ? 0 : 1]).to_sym # old style: git:name:path, new style: name:path

      repo = nil
      #puts "REPO SELECTOR: >>>>>>>>> #{opts[:repo_iterator]}"
      if opts[:repo_iterator]
        repo = opts[:repo_iterator].find {|r| r.name == name}
      else
        repo = @@repositories[name.to_sym]
      end
      unless repo
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

    def self.register_mime_type(mapping)
      MIME_TYPE.merge!(mapping)
    end

    attr_reader :name, :top_dir

    # params opts [Hash]
    # opts read_only [Boolean] If true, write will fail
    # opts create_if_not_exists [Boolean]
    def initialize(name, opts)
      @name = name
      @url_prefix = "#{@name}:"
      @read_only = (opts[:read_only] == true)

      if @top_dir = opts[:top_dir]
        if @top_dir.start_with?('.') && ContentRepository.reference_dir
          @top_dir = File.join(ContentRepository.reference_dir, @top_dir)
        end
        unless @top_dir =~ /^.+@.+:(.+)\.git$/
          @top_dir = File.expand_path(@top_dir)
        end
        debug "Creating repo '#{name} with top dir: #{@top_dir}"

        _create_if_not_exists if opts[:create_if_not_exists]
      end
    end

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
      # TODO: Make sure that key is really unique across multiple repositories - why?
      descr = descr ? descr.dup : {}
      url = get_url_for_path(path)
      descr[:url] = url
      descr[:path] = path
      descr[:name] = url # Should be something human digestable
      if (descr[:strictly_new])
        return nil if exist?(path)
      end
      proxy = ContentProxy.create(descr, self)
      return proxy
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

    def exist?(path)
      Dir.chdir(@top_dir) do
        return nil if File.exist?(path)
      end
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

    def _get_path(content_descr)
      if content_descr.is_a? String
        # Old style (file:name:path) vs. new style (name:path)
        path = content_descr.split(':')[-1]
        unless path
          raise "Can't find path information in '#{content_descr.inspect}'"
        end
      elsif content_descr.is_a? Hash
        if (url = content_descr[:url])
          path = url.split(':')[-1]
        else
          path = content_descr[:path]
        end
        unless path
          raise "Missing 'path' or 'url' in content description (#{content_descr.inspect})"
        else
          path = path.to_s
        end
      else
        raise "Unsupported type '#{content_descr.class}'"
      end

      return path
    end

    # Return a URL for a path in this repo
    #
    def get_url_for_path(path)
      @url_prefix + path
    end

    # Make the repo references less verbose
    def to_s
      #"\#<#{self.class}-#{@name} - #{@top_dir}>"
      "\#<#{self.class}-#{@name}>"
    end

    protected

    def _create_if_not_exists
      raise NotImplementedError, "#{__method__} NOT implementated in #{self.class}"
    end
  end # class
end # module
