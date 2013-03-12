

module IRODS4r
  
  # This class proxies a directory in an iRODS environment
  #
  class Directory
        
    def list()
      FileEnumerator.new(@dir_name)
    end
    
    def file?
      return false
    end
    
    def directory?
      return true
    end
    
    def initialize(dir_name)
      @dir_name = dir_name
    end
  end
  
  class FileEnumerator
    include Enumerable
    
    def each()
      while e = @entries.shift
        e = e.strip
        if e.start_with? 'C-'
          # it's a directory
          yield Directory.new(e[3 .. -1])
        else
          yield File.new(::File.join(@dir_name, e))
        end
      end
    end

    def initialize(dir_name)
      r = `ils #{dir_name}`
      @dir_name = dir_name
      @entries = r.lines.to_a
      @entries.shift # the first line is the directory name again
    end
  end
end