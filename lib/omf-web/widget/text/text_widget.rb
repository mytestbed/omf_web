require 'omf-web/widget/abstract_widget'
require 'omf-web/widget/text/maruku'
require 'omf-web/content/repository'

module OMF::Web::Widget

  # Supports widgets which displays text with 
  # potentially other widgets embedded.
  #
  class TextWidget < AbstractWidget
    
    def self.create_text_widget(type, wdescr)
      return self.new(wdescr)
    end
    
    def initialize(opts)
      opts = opts.dup # not sure why we may need to this. Is this hash used anywhere else?
      super opts      

      unless (content_descr = opts[:content])
        raise "Missing 'content' option in '#{opts.inspect}'"
      end      
      @content_proxy = OMF::Web::ContentRepository[opts].load(content_descr)
      
      @content = OMF::Web::Widget::Text::Maruku.format_content(@content_proxy)
      @opts[:title] = @content.attributes[:title] || opts[:title]
      @widgets = @content.attributes[:widgets] || []
    end
    
    def content()
      @content = OMF::Web::Widget::Text::Maruku.format_content(@content_proxy)
      @opts[:title] = @content.attributes[:title] || opts[:title]
      @widgets = @content.attributes[:widgets] || []
      
      OMF::Web::Theme.require 'text_renderer'
      OMF::Web::Theme::TextRenderer.new(self, @content, @opts)
    end

    def content_url
      @content_proxy.content_url
    end

    def content_id
      @content_proxy.content_id
    end

    def collect_data_sources(ds_set)
      @widgets.each {|w| w.collect_data_sources(ds_set) }
      ds_set
    end

  end
end

