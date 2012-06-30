

module OMF::Web::Theme
  @@search_order = ['omf-web/theme/bright']  # default theme
  @@loaded = {}
  
  def self.theme=(theme)
    if theme
      unless theme.match '.*/'
        theme = "omf-web/theme/#{theme}" # add default name space
      end
      @@loaded = {}
      @@search_order = [theme] 
      Kernel::require "#{theme}/init"
    end
  end
  
  # Set additional themes to search in the given order for 
  # implementations of renderes. Allows for partial override
  # in new themes.
  #
  def self.search_order=(search_order)
    @@loaded = {}
    @@search_order = search_order if search_order
  end
  
  
  def self.require(name)
    return if @@loaded[name]
    @@search_order.each do |theme|
      begin
        puts "Checking for '#{theme}/#{name}.rb'"
        Kernel::require "#{theme}/#{name}"
        @@loaded[name] = true
        return
      rescue LoadError
        # Move on to the next one
      end
    end
    raise "Can't find theme component '#{name}' in '#{@@search_order.join(', ')}"
  end
end