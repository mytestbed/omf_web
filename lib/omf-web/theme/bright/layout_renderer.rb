
require 'omf-web/theme/bright/widget_chrome'

module OMF::Web::Theme
  
  class LayoutRenderer < Erector::Widget
    
    def render? partial
      a = (@opts[:render] ||= {})[partial] 
      a != false
    end

  end # class

end # OMF::Web::Theme
