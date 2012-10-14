
require 'omf-web/theme/abstract_page'

module OMF::Web::Theme

  class MustacheRenderer < Erector::Widget
    
    def initialize(widget, opts)
      super opts
      @widget = widget
      @opts = opts
    end
        
    def content()
      base_id = "mr#{self.object_id}"
      opts = @opts.dup
      opts[:base_id] = base_id
      div :id => base_id, :class => "mustache_widget" do
        javascript(%{
          L.require('#OML.mustache', 'js/mustache', function() {
            OML.mustache(#{opts.to_json});
          });
        })
      end
    end
    
  end
  
end
