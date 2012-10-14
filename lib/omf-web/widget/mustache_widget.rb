
require 'omf-web/widget/abstract_widget'
require 'omf-web/content/repository'

module OMF::Web::Widget
  
  # Renders the content of a moustache file in the context of a data source
  #
  class MustacheWidget < AbstractWidget
    
    def self.create_mustache_widget(type, wdescr)
      return self.new(wdescr)
    end
    
    attr_accessor :content_proxy
    
    def initialize(opts)
      super opts
      # if (content_descr = opts[:content])
        # opts[:content_proxy] = OMF::Web::ContentRepository.create_content_proxy_for(content_descr, opts)  
      # end  
    end
    
    def title 
      @opts[:title] || 'No Title'
    end
       
    def content()
      OMF::Web::Theme.require 'mustache_renderer'
      OMF::Web::Theme::MustacheRenderer.new(self, @opts)
    end
    
    def collect_data_sources(ds_set)
      if @opts[:data_sources]
        @opts[:data_sources].each do |ds|
          ds_set.add(ds[:stream])
        end
      end
      ds_set
    end
    
  end # class
  
end
