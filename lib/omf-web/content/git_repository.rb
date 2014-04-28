
#require 'base64'
require 'grit'
require 'find'
require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'

module OMF::Web

  # This class provides an interface to a GIT repository
  # It retrieves, archives and versions content.
  #
  class GitContentRepository < ContentRepository

    attr_reader :name, :top_dir

    def initialize(name, opts)
      super
      @repo = Grit::Repo.new(@top_dir)
    end

    def write(content_descr, content, message)
      raise ReadOnlyContentRepositoryException.new if @read_only

      path = _get_path(content_descr)
      Dir.chdir(@top_dir) do
        d_name = File.dirname(path)
        FileUtils.mkpath(d_name) unless File.exist?(d_name)
        unless File.writable?(path) || File.writable?(d_name)
          raise "Cannot write to file '#{path}'"
        end
        f = File.open(path, 'w')
        f.write(content)
        f.close

        @repo.add(path)
        # TODO: Should set info about committing user which should be in thread context
        @repo.commit_index(message || 'no message')
      end
    end

    # Return a URL for a path in this repo
    #
    def get_url_for_path(path)
      @url_prefix + path
    end

    #
    # Return an array of file names which are in the repository and
    # match 'search_pattern'
    #
    def find_files(search_pattern, opts = {})
      search_pattern = Regexp.new(search_pattern)
      tree = @repo.tree
      res = []
      fs = _find_files(search_pattern, tree, nil, res)
      fs
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
            #path = @url_prefix + long_name
            path = long_name
            res << {path: path, url: get_url_for_path(path), name: e.name,
                    mime_type: mt,
                    #:id => Base64.encode64(long_name).gsub("\n", ''),
                    size: e.size, blob: e.id}
          end
        end
      end
      res
    end

    def _get_path(content_descr)
      if content_descr.is_a? String
        path = content_descr.to_s
        if path.start_with? 'git:'
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
      if path.start_with? '/'
        # Remove leading '/' .. need to stay within git directory tree
        path = path[1 .. -1]
      end
      return path
    end

  end # class
end # module
