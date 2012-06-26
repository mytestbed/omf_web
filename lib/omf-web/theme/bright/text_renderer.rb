
require 'omf-web/theme/bright/widget_chrome'

module OMF::Web::Theme
  
  class TextRenderer < Erector::Widget
    
    def initialize(text_widget, content, opts)
      super opts
      @widget = text_widget
      @content = content
    end
    
    def content
      wid = "w#{@widget.object_id}"
      div :class => "text" do
        rawtext @content.to_html
        javascript(%{
          OHUB.bind("content.changed.#{@widget.content_id}", function(evt) {
            $.ajax({
              url: '/widget/#{@widget.widget_id}?embedded&body_only',
              type: 'GET'
            }).done(function(data) { 
              $('\##{wid}_b').replaceWith(data);
              var i = 0;
            });
          });
        })
      end
      
    end
      
  end 

end # OMF::Web::Theme
