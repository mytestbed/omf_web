
require 'irods4r/directory'

module IRODS4r

  #class NotFoundException < Exception; end
  class NoFileException < Exception; end
  class FileExistsException < Exception; end

  # This class proxies a file in an iRODS environment
  #
  class File

    # Create a file resource 'path'. If 'must_not_exist' is true,
    # throw exception if resource already exists.
    #
    def self.create(path, must_not_exist = true, opts = {})
      if must_not_exist
        raise FileExistsException.new(path) if ICommands.exist?(path)
      end
      self.new(path, opts)
    end


    # Return the content of this file
    def read()
      ICommands.read(@path, @ticket)
    end

    # Write content to this file.
    #
    # WARN: This will overwrite any previous content
    #
    def write(content)
      ICommands.write(@path, content, @ticket)
    end

    def file?
      return true
    end

    def directory?
      return false
    end

    attr_reader :path

    private
    def initialize(path, opts = {})
      @path = path
      @ticket = opts[:ticket]
    end
  end
end
