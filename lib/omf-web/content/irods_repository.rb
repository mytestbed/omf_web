
require 'find'
require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'
require 'irods4r'

module OMF::Web

  # This class provides an interface to a directory based repository
  # It retrieves, archives and versions content.
  #
  class IRodsContentRepository < ContentRepository

    @@irods_repositories = {}

    # Return the repository which is referenced to by elements in 'opts'.
    #
    #
    def self.[](name)
      unless repo = @@irods_repositories[name.to_sym]
        raise "Unknown iRODS repo '#{name}'"
      end
      repo
    end

    # Register an existing directory to the system. It will be
    # consulted for all content url's starting with
    # 'irods:_top_dir_:'. If 'is_primary' is set to true, it will
    # become the default repo for all newly created content
    # in this app.
    #
    def self.register_file_repo(name, top_dir, is_primary = false)
      name = name.to_sym
      if @@irods_repositories[name]
        warn "Ignoring repeated registration of iRODS rep '#{name}'"
        return
      end
      repo = @@irods_repositories[name] = self.new(name, top_dir)
      if is_primary
        @@primary_repository = repo
      end
    end

    attr_reader :name, :top_dir

    def initialize(name, opts)
      super
      unless @top_dir
        raise "No top_dir defined (#{opts.keys.inspect})"
      end
      @url_prefix = "irods:#{name}:"
      @ticket = opts[:ticket]
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
      # TODO: Make sure that key is really unique across multiple repositories
      descr = descr ? descr.dup : {}
      url = get_url_for_path(path)
      key = Digest::MD5.hexdigest(url)
      descr[:url] = url
      descr[:url_key] = key
      descr[:path] = path
      descr[:name] = url # Should be something human digestable
      if (descr[:strictly_new])
       return nil if IRODS4r.exists?(path, @ticket)
      end
      proxy = ContentProxy.create(descr, self)
      return proxy
    end

    def write(content_descr, content, message)
      path = _get_path(content_descr)
      #puts "WRITE PATHS>>> #{path}"
      f = IRODS4r::File.create(path, false, ticket: @ticket)
      f.write(content)
    end

    def read(content_descr)
      path = _get_path(content_descr)
      #puts "READ PATHS>>> #{path}"
      f = IRODS4r::File.create(path, false, ticket: @ticket)
      f.read()
    end

    #
    # Return an array of file names which are in the repository and
    # match 'search_pattern'
    #
    def find_files(search_pattern, opts = {})
      begin
        dir = IRODS4r.find(@top_dir, {}, @ticket)
      rescue IRODS4r::IRODS4rException
        return []
      end
      res = []
      _find_files(search_pattern, dir, res, opts[:mime_type])
      res
    end

    def _find_files(search_pattern, dir, res, mime_type)
      dir.list.each do |e|
        if e.directory?
          _find_files(search_pattern, e, res, mime_type)
        else
          path = e.path
          if path.match(search_pattern)
            mt = mime_type_for_file(path)
            # subselect mime type in class method
            #next if mime_type != nil && !File.fnmatch(mime_type, mt)
            res << {:url => get_url_for_path(path), :path => path, #:name => 'foo',
                    :mime_type => mt}
          end
        end
      end
      res
    end


    # Return a URL for a path in this repo
    #
    def get_url_for_path(path)
      # puts "PATH>>>>> '#{path}:#{path.class}'-'#{@top_dir}:#{@top_dir.class}'"
      if m = path.match("#{@top_dir}(.*)")
        path = m[1]
      end
      url = @url_prefix + path
    end

    # HACK ALERT!!!
    #
    # This method may be called by an entity which wants to access the content
    # directly through the file system. In the absence of a FUSE mounted iRODS
    # repo, we 'iget' the resource to a temporary directory and return that
    # path. The calling entity needs to be aware that any changes to that file
    # will NOT show up in iRODS without an iput.
    #
    # This should really NOT be necessary. Use FUSE
    #
    def absolute_path(content_descr)
      path = _get_path(content_descr)

      require 'etc'
      tmp_dir = "#{Dir::tmpdir}/LabWiki-#{Etc.getlogin}"
      # unless Dir.exists? tmp_dir
        # Dir.mkdir tmp_dir, 0700
      # end

      target = File.join(tmp_dir, path)
      IRODS4r::ICommands.export(path, target, true, @ticket)
      target
    end


    def _get_path(content_descr)
      #puts ">>>GET PATH #{content_descr.inspect}"
      if content_descr.is_a? String
        path = content_descr.to_s
        if path.start_with? 'irods:'
          path = File.join(@top_dir, path.split(':')[2])
        end
      elsif content_descr.is_a? Hash
        descr = content_descr
        unless path = descr[:path]
          if url = descr[:url]
            path = File.join(@top_dir, url.split(':')[2]) # irods:repo_name:path
          end
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
