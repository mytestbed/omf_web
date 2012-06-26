
require 'coderay'
require 'omf-web/theme/abstract_page'

module OMF::Web::Theme

  class CodeRenderer < Erector::Widget
    
    depends_on :css, "/resource/css/coderay.css"
    
    def initialize(widget, content, opts)
      super opts
      @widget = widget
      @content = content
      @opts = opts
    end
        
    def content()
      
      base_id = "cm#{self.object_id}"
      edit_id = base_id + '_e'
      mode = 'markdown'

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
        div :class => "codemirror_toolbar_container" do
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
        link :href => "/resource/css/theme/bright/codemirror.css", 
            :media => "all", :rel => "stylesheet", :type => "text/css"

        ['codemirror', 'util/dialog', 'util/searchcursor', 'util/search', 'util/loadmode'].each do |f|
          script :src => "/resource/vendor/codemirror/lib/#{f}.js"
        end
        
        #script :src => "/resource/vendor/codemirror/mode/xml/xml.js"
        #script :src => "/resource/vendor/codemirror/mode/#{mode}/#{mode}.js"

        # Div where the text should go
        div :id => edit_id, :class => "codemirror_edit" #, :style => 'height:100%'
         
        javascript(%{
          L.require('#OML.code_mirror', 'graph/code_mirror.js', function() {
            OML.widgets.#{base_id} = new OML.code_mirror(#{opts.to_json});
            #{js_toolbar.join("\n");}
          });
        })
      end

        
      # tid = "ta#{self.object_id}"
      # form do
        # textarea :id => tid, :style => 'width:100%;height:100%'   do
          # rawtext @content
        # end
      # end
      # javascript(%{
        # OML.widgets.#{tid} = CodeMirror.fromTextArea(document.getElementById("#{tid}"), {
          # mode: "#{mode}",
          # lineNumbers: true,
          # matchBrackets: true,
          # tabMode: "indent",
#           
        # });
        # window.onbeforeunload = function() {
          # return 'You may have unsaved changes!';
        # }
      # }) 
        
    end

    def content2()
      link :href => "/resource/css/coderay.css", 
        :media => "all", :rel => "stylesheet", :type => "text/css"     
      div :class => "oml_code CodeRay" do
        rawtext(@content.html :line_numbers => :inline, :tab_width => 2, :wrap => :div)
      end
    end
    
  end
  
end
