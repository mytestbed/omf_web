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
      div :id => @base_id, :class => "#{@js_class.gsub('.', '_').downcase}" do
        javascript(%{
          require(['#@js_module'], function(Graph) {
            var w = OML.widgets.#{@base_id} = new Graph(#{@wopts.to_json});
            var i = 0;
          });
        })
      end
    end

  end
end