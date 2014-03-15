require 'omf-web/widget/abstract_widget'

module OMF::Web::Widget::Layout

  # Implements a layout which displays only one of the widget it contains
  # but provides theme specific means to switch between them.
  #
  class StackedLayout < OMF::Web::Widget::AbstractWidget
    attr_reader :active_index

    def initialize(opts)
      super opts
      widgets = opts[:widgets]
      @widgets = widgets.collect {|w| OMF::Web::Widget.create_widget(w) }
      @active_index = 0
      @active_widget = @widgets[0]
    end

    def content()
      OMF::Web::Theme.require 'stacked_renderer'
      OMF::Web::Theme::StackedRenderer.new(self, @widgets, @active_index, @opts)
    end


    def collect_data_sources(ds_set)
      #puts "ACTIVE>>> #{@active_widget.class}"
      @active_widget.collect_data_sources(ds_set)
      ds_set
    end

    def name
      @opts[:name] || @active_widget.name
    end

    def layout?
      return true
    end

  end
end
