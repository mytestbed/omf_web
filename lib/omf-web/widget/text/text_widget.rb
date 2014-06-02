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
      # if content_descr.is_a? OMF::Web::ContentProxy
        # self.content_proxy = content_descr
      # else
        # #self.content_proxy = OMF::Web::ContentRepository[opts].load(content_descr)
        # self.content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(content_descr, opts)
      # end
      self.content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(content_descr, opts)
    end

    def content_proxy=(content_proxy)
      @content_proxy = content_proxy
    end

    def content()
      update()
      OMF::Web::Theme.require 'text_renderer'
      @opts[:title] = @content.attributes[:title] || opts[:title]
      OMF::Web::Theme::TextRenderer.new(self, @content, @opts)
    end

    def update()
      # Could avoid doing the next three steps every time if we would know if the
      # content in content_proxy has changed.
      @content = OMF::Web::Widget::Text::Maruku.format_content_proxy(@content_proxy)
      @widgets = @content.attributes[:widgets] || []
    end


    def content_url
      @content_proxy.content_url
    end

    def content_id
      @content_proxy.content_url
    end

    def mime_type
      'text/html'
    end

    def collect_data_sources(ds_set)
      update()
      @widgets.each {|w| w.collect_data_sources(ds_set) }
      ds_set
    end

  end
end

