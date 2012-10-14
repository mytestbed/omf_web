
require 'omf-web/theme/bright/layout_renderer'

module OMF::Web::Theme
  
  class OneColumnRenderer < LayoutRenderer
    
    def initialize(widgets, opts)
      super opts
      @opts = opts
      @widgets = widgets
    end
    
    def content
      div :class => 'one_column' do
        @widgets.each do |w|
          render_widget w
        end
      end
    end
        
    def render_widget(w)
      r = w.content
      unless w.layout?
        r = WidgetChrome.new(w, r, @opts)
      end
      rawtext r.to_html      
    end    

  end # OneColumnRenderer

end # OMF::Web::Theme
