
#require 'coderay'
require 'omf-web/theme/abstract_page'

module OMF::Web::Theme

  class CodeRenderer < Erector::Widget
    
    #depends_on :css, "/resource/css/coderay.css"
    
    # This maps the content's mime type to a different mode  supported
    # CodeMirror
    #
    MODE_MAPPER = {
      :markup => :markdown
    }
    
    def initialize(widget, content, mode, opts)
      super opts
      @widget = widget
      @content = content
      @mode = MODE_MAPPER[mode.to_sym] || mode
      @opts = opts
    end
        
    def content()
      
      base_id = "cm#{self.object_id}"
      edit_id = base_id + '_e'
      mode = @mode

      opts = @opts.dup
      opts.delete :id
      opts.delete :layout
      opts.delete :top_level
      opts.delete :priority
      opts.merge!(
        :base_el => "#" + base_id, 
        :edit_el => '#' + edit_id, 
        :content => @content.to_s, 
        :mode => mode,
        :content_id => @widget.content_id,
        :save_url => @widget.update_url
      )

      div :id => base_id, :class => "codemirror_widget" do
        
        js_toolbar = []
        div :class => "codemirror_toolbar_container widget-toolbar" do
          ol :class => "codemirror_toolbar" do
            ['save', 'undo', 'redo'].each do |name|
              id = "#{base_id}_#{name}_a"
              li :class => 'cmd_' + name do
                a :id => id, :href => "#"  do
                  span name, :class => :codemirror_toolbar
                end
              end
              js_toolbar << %{
                $('\##{id}').click(function(){
                  OML.widgets.#{base_id}.on_#{name}_pressed();
                  return false;
                });
              } 
            end
          end
        end
        
        ['codemirror', 'util/dialog'].each do |f|
          link :href => "/resource/vendor/codemirror/lib/#{f}.css", 
            :media => "all", :rel => "stylesheet", :type => "text/css"
        end

        ['codemirror', 'util/dialog', 'util/searchcursor', 'util/search', 'util/loadmode'].each do |f|
          script :src => "/resource/vendor/codemirror/lib/#{f}.js"
        end
        
        #script :src => "/resource/vendor/codemirror/mode/xml/xml.js"
        #script :src => "/resource/vendor/codemirror/mode/#{mode}/#{mode}.js"

        # Div where the text should go
        div :id => edit_id, :class => "codemirror_edit" #, :style => 'height:100%'
         
        render_widget_creation(base_id, opts)
        javascript(%{
          #{js_toolbar.join("\n");}
        })
        
      end        
    end
    
    def render_widget_creation(base_id, opts)
      link :href => "/resource/theme/bright/css/codemirror.css", 
          :media => "all", :rel => "stylesheet", :type => "text/css"
      
      javascript(%{
        L.require('#OML.code_mirror', 'graph/js/code_mirror', function() {
          OML.widgets.#{base_id} = new OML.code_mirror(#{opts.to_json});
        });
      })
    end

    # def content2()
      # link :href => "/resource/css/coderay.css", 
        # :media => "all", :rel => "stylesheet", :type => "text/css"     
      # div :class => "oml_code CodeRay" do
        # rawtext(@content.html :line_numbers => :inline, :tab_width => 2, :wrap => :div)
      # end
    # end
    
  end
  
end
