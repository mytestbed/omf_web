require 'omf-web/theme/abstract_page'

module OMF::Web::Theme

  class DataRenderer < Erector::Widget

    def initialize(widget, opts)
      super opts
      @base_id = widget.dom_id
      @js_class = opts[:js_class]
      @js_url = opts[:js_url]
      @js_module = opts[:js_module]
      @wopts = opts.dup
    end

    def content()
      #div :id => @base_id, :class => "omf_data_widget #{@js_class.gsub('.', '_').downcase}" do
      div :id => @base_id, :class => "omf_data_widget_container" do
        javascript(%{
        /*
          require(['#@js_module'], function(Graph) {
            var w = OML.widgets.#{@base_id} = new Graph(#{@wopts.to_json});
            var i = 0;
          });
        */
          (OML.widget_proto.#{@base_id} = function(id) {
            var inner_el = id + "_i";
            $("#" + id).append("<div id='" + inner_el + "' class='omf_data_widget #{@js_class.gsub('.', '_').downcase}' />")
            var opts = #{@wopts.to_json};
            opts.base_el = "#" + inner_el;
            require(['#@js_module'], function(Graph) {
              OML.widgets[id] = new Graph(opts);
            });
          })('#{@base_id}');
        })
      end
    end

  end
end