
require 'erector'
require 'omf_base/lobject'

module OMF::Web::Widget
      
  # Maintains the context for a particular code rendering within a specific session.
  #
  class AbstractWidget < Erector::Widget
    extend OMF::Base::Loggable
    include OMF::Base::Loggable    
    
    attr_reader :widget_id, :widget_type, :name, :opts
    
    def initialize(opts = {})
      super
      @opts = opts
      @widget_id = opts[:id]
      unless @name = opts[:name]
        @name = opts[:id] #? opts[:id].to_s.capitalize : 'Unknown: Set opts[:name]' 
      end 
      unless @widget_type = opts[:type]
        raise "Missing 'type' in '#{opts.inspect}'"
      end 
      OMF::Web::SessionStore[@widget_id, :w] = self
    end
    
    # Return text to provide information about this widget
    #
    def widget_info()
      @opts[:info] || 'No information available'
    end
    

    # Return html for an optional widget tools menu to be added
    # to the widget decoration by the theme.
    # 
    def tools_menu()
      # Nothing
    end
    
    def layout?
      return false
    end
    
    def title
      @opts[:title]
    end
    
    def mime_type
      @opts[:mime_type] || 'unknown'
    end
    
    def collect_data_sources(ds_set)
      raise "Should have been implemented"
    end
    
    
        
  end # class
    

end # OMF::Web::Widget