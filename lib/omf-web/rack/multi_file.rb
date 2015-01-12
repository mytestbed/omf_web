
require 'rack/file'

module OMF::Web::Rack
  # Rack::MultiFile serves files which it looks for below an array
  # of +roots+ directories given, according to the
  # path info of the Rack request.
  #
  # Handlers can detect if bodies are a Rack::File, and use mechanisms
  # like sendfile on the +path+.
  #
  class MultiFile < ::Rack::File
    def initialize(roots, opts = {})
      super nil, opts[:cache_control]
      @roots = roots
      if opts[:sub_path]
        @sub_path = opts[:sub_path].split ::Rack::Utils::PATH_SEPS
      end
      if @version = opts[:version]
        # read VERSION_MAP.yaml files
        @version_map = {}
        require 'yaml'
        yml = File.join((@sub_path || []), 'VERSION_MAP.yaml')
        @roots.reverse.each do |dir|
          fn = File.join(dir, yml)
          #puts "Checking for #{fn}"
          if File.readable?(fn)
            mh = YAML.load_file(fn)
            #puts "VERSIONS: #{mh.inspect}"
            @version_map.merge!(mh)
          end
        end
      end
    end

    def _call(env)
      @path_info = ::Rack::Utils.unescape(env["PATH_INFO"])
      parts = @path_info.split ::Rack::Utils::PATH_SEPS
      if @version_map
        if pkg_name = @version_map[parts[1]]
          parts[1] = pkg_name # replace with version
        end
      end
      if @sub_path
        parts = @sub_path + parts
      end

      return fail(403, "Forbidden")  if parts.include? ".."

      @roots.each do |root|
        @path = F.join(root, *parts)
        #puts ">>>> CHECKING #{@path}"
        available = begin
          F.file?(@path) && F.readable?(@path)
        rescue SystemCallError
          false
        end

        if available
          return serving(env)
        end
      end
      fail(404, "File not found: #{@path_info}")
    end # _call

  end # MultiFile
end # module



