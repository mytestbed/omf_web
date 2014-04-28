
require 'find'
require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/content/content_proxy'
require 'omf-web/content/repository'

module OMF::Web

  # This class provides an interface to a directory based repository
  # It retrieves, archives and versions content.
  #
  class FileContentRepository < ContentRepository

    def initialize(name, opts)
      super
      #@url_prefix = "file:#{name}:"
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
      end
    end

    #
    # Return an array of file names which are in the repository and
    # match 'search_pattern'
    #
    def find_files(search_pattern, opts = {})
      Dir.chdir(@top_dir)
      Dir.glob("**/*#{search_pattern}*").map do |path|
        next if File.directory?(path)
        mt = mime_type_for_file(path)
        {
          name: path,
          url: get_url_for_path(path),
          mime_type: mt,
          size: File.size(path)
        }
      end.compact
    end

    def _get_path(content_descr)
      if content_descr.is_a? String
        path = content_descr.to_s
        parts = path.split(':')
        path = parts[-1] # old style (file:name:path) vs. new style (name:path)
      elsif content_descr.is_a? Hash
        descr = content_descr
        if (url = descr[:url])
          path = url.split(':')[-1]
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
