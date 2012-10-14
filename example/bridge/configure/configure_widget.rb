require 'omf-web/widget/abstract_widget'


  # Implements a widget to configure the state of the system
  #
  class ConfigureWidget < AbstractWidget

    attr_reader :name, :opts #:base_id


    # opts
    #
    def initialize(opts = {})
    end
    
    # This is the DOM id which should be used by the renderer for this widget. 
    # We need to keep this here as various renderes at various levels may need
    # to get a reference to it to allow for such functionalities as 
    # hiding, stacking, ...
    # def dom_id
      # "w#{object_id.abs}"
    # end

    def content()
      OMF::Web::Theme.require 'data_renderer'
      OMF::Web::Theme::DataRenderer.new(self, @opts)
    end




  end # class
