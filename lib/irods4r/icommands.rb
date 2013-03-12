

module IRODS4r
  
  # This module interfaces directly with the IRODS system
  #
  module ICommands
    class ICommandException < IRODS4rException; end
      
    # Return the list of files found at 'path'. 
    def self.ls(path)
      r = `ils #{path}`
      #raise ICommandException.new($?) unless $?.exitstatus == 0
      if r.empty?
        raise NotFoundException.new("Can't find resource '#{irodsPath}'")
      end 
      r.lines
    end
    
    # Return content of resource at 'path'
    #
    def self.read(path)
      f = Tempfile.new('irods4r')
      `iget -f #{path} #{f.path}`
      raise CommandException.new($?) unless $?.exitstatus == 0
      content = f.read
      f.close
      f.unlink
      content
    end
    
    # Return content of resource at 'path'
    #
    def self.write(path, content)
      f = Tempfile.new('irods4r')
      f.write(content)
      f.close
      `iput -f #{f.path} #{path}`
      raise CommandException.new($?) unless $?.exitstatus == 0
      f.unlink
    end

    def self.exist?(path)
      `ils #{path}`
      $?.exitstatus == 0
    end
    
  end #module
end # module
      
