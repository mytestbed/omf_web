

module IRODS4r

  class IRODS4rException < StandardError; end
  class NotFoundException < IRODS4rException; end
  class NoDirectoryException < IRODS4rException; end

  # Return a IRODS4r object for 'irodsPath' if it exists.
  #
  # @param [String] irodsPath Absolute path into iRODS
  # @param [Hash] opts Options to use for establishing context
  # @return [Directory|File]
  #
  def self.find(irodsPath = ".", opts = {}, ticket = nil)
    r = ICommands.ls(irodsPath, ticket)
    name = r.to_a[0].strip
    if name.end_with? ':'
      Directory.new(name[0 ... -1])
    else
      File.new(name)
    end
  end

  # Return true if 'path' exists
  def self.exists?(path, ticket = nil)
    ICommands.exist?(path, ticket)
  end
end

require 'irods4r/directory'
require 'irods4r/file'
require 'irods4r/icommands'

