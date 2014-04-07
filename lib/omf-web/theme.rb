

module OMF::Web::Theme
  extend OMF::Base::Loggable

  DEFAULT_THEME = 'omf-web/theme/bright'
  @@search_order = [DEFAULT_THEME]  # default theme
  @@loaded = {}
  @@additional_renderers = {}

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

  def self.include_css(css_file)
    ::Kernel.require 'omf-web/theme/abstract_page'
    OMF::Web::Theme::AbstractPage.add_depends_on(:css, "/resource/#{css_file}")
  end

  def self.register_renderer(name, klass, theme = DEFAULT_THEME)
    tr = @@additional_renderers[theme.to_s] ||= {}
    tr[name] = klass
  end

  # Set additional themes to search in the given order for
  # implementations of renderes. Allows for partial override
  # in new themes.
  #
  def self.search_order=(search_order)
    @@loaded = {}
    @@search_order = search_order if search_order
  end

  # Return a named renderer for this theme initialised with 'widget'
  #
  def self.create_renderer(name, widget)
    name = name.to_sym
    @@search_order.each do |theme|
      if tr = @@additional_renderers[theme.to_s]
        if klass = tr[name]
          #self.require(name)
          return klass.new(widget)
        end
      end
    end
    raise "Can't find class implementing renderer '#{name}' in '#{@@search_order.join(', ')}'"
  end

  def self.require(name)
    name = name.to_sym
    return if @@loaded[name]
    @@search_order.each do |theme|
      begin
        # check if there is a registered renderer. Assumes to be already loaded
        unless (@@additional_renderers[theme.to_s] || {})[name]
          #puts "Checking for '#{theme}/#{name}.rb'"
          Kernel::require "#{theme}/#{name}"
        end
        @@loaded[name] = true
        debug "Using renderer '#{theme}/#{name}'"
        return
      rescue LoadError => le
        # Move on to the next one
        #puts ">>>> #{le}"
      end
    end
    raise "Can't find theme component '#{name}' in '#{@@search_order.join(', ')}'"
  end
end
