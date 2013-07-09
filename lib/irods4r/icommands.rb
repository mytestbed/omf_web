
require 'irods4r'

module IRODS4r

  # This module interfaces directly with the IRODS system
  #
  module ICommands
    class ICommandException < IRODS4rException; end

    # Return the list of files found at 'path'.
    def self.ls(path, ticket = nil)
      r = `ils #{"-t #{ticket}" if ticket} #{path}`
      #raise ICommandException.new($?) unless $?.exitstatus == 0
      if r.empty?
        raise NotFoundException.new("Can't find resource '#{path}'")
      end
      r.lines
    end

    # Return content of resource at 'path'
    #
    def self.read(path, ticket = nil)
      f = Tempfile.new('irods4r')
      `iget -f #{"-t #{ticket}" if ticket} #{path} #{f.path}`
      raise ICommandException.new($?) unless $?.exitstatus == 0
      content = f.read
      f.close
      f.unlink
      content
    end

    # Return content of resource at 'path'
    #
    def self.write(path, content, ticket = nil)
      f = Tempfile.new('irods4r')
      f.write(content)
      f.close
      `iput -f #{"-t #{ticket}" if ticket} #{f.path} #{path}`
      raise ICommandException.new($?) unless $?.exitstatus == 0
      f.unlink
    end

    def self.exist?(path, ticket = nil)
      `ils #{"-t #{ticket}" if ticket} #{path}`
      $?.exitstatus == 0
    end

    # Copy the resource at 'path' in iRODS to 'file_path'
    # in the local file system.
    #
    def self.export(path, file_path, create_parent_path = true, ticket = nil)
      #puts ">>>> #{path} -> #{file_path}"
      if create_parent_path
        require 'fileutils'
        FileUtils.mkpath ::File.dirname(file_path)
      end
      `iget -f #{"-t #{ticket}" if ticket} #{path} #{file_path}`
      raise ICommandException.new($?) unless $?.exitstatus == 0
    end
  end #module
end # module

