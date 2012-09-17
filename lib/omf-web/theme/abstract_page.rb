require 'erector'

require 'omf-web/data_source_proxy'

module OMF::Web::Theme
  class AbstractPage < Erector::Widget
    
    depends_on :js,  '/resource/vendor/stacktrace/stacktrace.js'
    depends_on :js, '/resource/vendor/jquery/jquery.js'
    #depends_on :js, '/resource/js/stacktrace.js'
    depends_on :js, '/resource/vendor/underscore/underscore.js'
    depends_on :js, '/resource/vendor/backbone/backbone.js'    
    depends_on :js, "/resource/js/require3.js"

    depends_on :js, "/resource/theme/abstract/abstract.js"
    depends_on :js, "/resource/js/data_source.js"    

    # depends_on :script, %{
      # L.baseURL = "/resource";
      # OML = {
        # data_sources: {},
        # widgets: {},
#         
      # };
#         
      # var OHUB = {};
      # _.extend(OHUB, Backbone.Events);
#       
      # $(window).resize(function(x) {
        # OHUB.trigger('window.resize', {});
      # });      
    # }
    
    attr_reader :opts
    
    def initialize(widget, opts)
      #puts "KEYS>>>>> #{opts.keys.inspect}"
      super opts
      @widget = widget
      @opts = opts
    end
    
    def render_flash
      return unless @flash
      if @flash[:notice] 
        div :class => 'flash_notice flash' do
          text @flash[:notice]
        end
      end
      if @flash[:alert]
        div :class => 'flash_alert flash' do
          a = @flash[:alert]
          if a.kind_of? Array
            ul do
              a.each do |t| li t end
            end
          else
            text a
          end
        end
      end
    end # render_flesh
    
    def render_data_sources
      return unless @widget
      
      require 'omf-oml/table'
      require 'set'
      
      dsh = {}
      @widget.collect_data_sources(Set.new).each do |ds|
        name = ds[:name].to_s
        dsh[name] = ds.merge(dsh[name] || {})
      end
      #puts ">>>> #{dsh.inspect}"
      return if dsh.empty?
      
      js = dsh.values.to_a.collect do |ds|
        render_data_source(ds)
      end
      # Calling 'javascript' doesn't seem to work here. No idea why, so let's do it by hand
      %{
        <script type="text/javascript">
          // <![CDATA[
            #{js.join("\n")}
          // ]]>
        </script>
      }
    end
    
    def render_data_source(ds, update_interval = -1)
      dspa = OMF::Web::DataSourceProxy.for_source(ds)
      dspa.collect do |dsp|
        dsp.reset()
        dsp.to_javascript(update_interval)
      end.join("\n")
    end
    
    def render_additional_headers
      #"\n\n<link href='/resource/css/incoming.css' media='all' rel='stylesheet' type='text/css' />\n"
    end

    def collect_data_sources(dsa)
      dsa
    end
  
    def to_html(opts = {})
      page_title = @title  # context may get screwed up below, so put title into scope
      b = super
      if @opts[:request].params.key?('embedded')
        b
      else
        e = render_externals << render_additional_headers << render_data_sources
        r = Erector.inline do
          instruct
          html do
            head do
              title page_title || "OMF WEB"
              #<link rel="shortcut icon" href="/resource/theme/@theme/img/favicon.ico">
              #<link rel="apple-touch-icon" href="/resource/theme/@theme/img/apple-touch-icon.png">
              text! e.join("\n")
            end
            body do
              text! b
            end
          end
        end
        r.to_html(opts)  
      end
    end
  end # class AbstractPage
end # OMF::Web::Theme
  