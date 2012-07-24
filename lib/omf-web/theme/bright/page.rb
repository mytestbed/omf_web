require 'omf-web/theme/abstract_page'

module OMF::Web::Theme
  class Page < OMF::Web::Theme::AbstractPage
    
    depends_on :css, '/resource/theme/bright/css/reset-fonts-grids.css'
    depends_on :css, "/resource/theme/bright/css/bright.css"
   
    depends_on :script, %{
      OML.show_widget = function(opts) {
        var prefix = opts.inner_class;
        var index = opts.index;
        var widget_id = opts.widget_id;
        
        $('.' + prefix).hide();
        $('#' + prefix + '_' + index).show();
        
        var current = $('#' + prefix + '_l_' + index);
        current.addClass('current');
        current.siblings().removeClass('current');
        
        // May be a bit overkill, but this should shake out the widgets hidden so far
        OHUB.trigger('window.resize', {}); 
        //var widget = OML.widgets[widget_id];
        //if (widget) widget.resize().update();
          
        return false;
      };
    }
       
    # def initialize(widget, opts)
      # super
    # end
 
    def content
      div :id => 'doc3' do
        div :id => 'hd' do
          render_top_line
          h1 @page_title || 'Missing :page_title' 
        end
        div :id => 'bd' do
          render_body
        end
        div :id => 'ft' do
          render_footer
        end
      end
    end
    
    def render_top_line
      div :id => :top_line do
        render_tab_menu
        render_tools_menu
      end
    end
        
    def render_tab_menu
      ol :id => :tab_menu do
        @tabs.each do |h|
          lopts = h[:id] == @tab ? {:class => :current} : {}
          li lopts do 
            a :href => "#{@prefix}/#{h[:id]}?sid=#{Thread.current["sessionID"]}" do
              span h[:name], :class => :tab_text
            end
          end
        end
      end
    end
            
    def render_tools_menu
      div :id => :tools_menu do
        a 'Log in', :href => '/login'
      end
    end
    
    def render_body
      render_flash
      render_card_body
    end
    
    def render_card_body
      return unless @widget
      Thread.current["top_renderer"] = self
      rawtext @widget.content.to_html
    end
        
    def render_footer
      if @footer_right.is_a? Proc
        widget(Erector.inline(&@footer_right))
      else
        span :style => 'float:right;margin-right:10pt' do
          text @footer_right || OMF::Web::VERSION
        end
      end
      if @footer_left.is_a? Proc
        widget(Erector.inline(&@footer_left))
      else
        text @footer_left || 'Brought to you by the TEMPO Team'
      end
        
    end
    

  

  end # class Page
end # OMF::Web::Theme