


require 'maruku'
require 'maruku/ext/math'
# Monkey patches to add line numbers to html output

require 'omf_base/lobject'
require 'omf_web'
require 'omf-web/widget/text/maruku/input/parse_block'
require 'omf-web/widget/text/maruku/output/to_html'
require 'omf-web/widget/text/maruku/helpers'

require 'rexml/document'
require 'yaml'

MaRuKu::Globals[:html_math_engine] = 'ritex'

module OMF::Web::Widget::Text

  module Maruku

    # # Fetch text and parse it
    # #
    # def self.load_content(source)
      # unless File.readable?(source)
        # raise "Cannot read text file '#{source}'"
      # end
      # content = File.open(source).read
      # ::Maruku.new(content)
    # end

    # Fetch text and parse it
    #
    def self.format_content_proxy(content_proxy)
      unless content_proxy.is_a? OMF::Web::ContentProxy
        raise "Expected content proxy, but got '#{content_proxy.class}'"
      end
      format_content(content_proxy.content)
    end

    def self.format_content(content)
      ::Maruku.new(content)
    end


    class WidgetElement < OMF::Base::LObject

      @@pre_create_handlers = []

      # Register a block which is presented with the
      # widget description (Hash) we are about to create. The
      # block is assumed to return a widget description.
      #
      def self.on_pre_create(&block)
        @@pre_create_handlers << block
      end

      def self.create(wdescr)
        wdescr = @@pre_create_handlers.reduce(wdescr) do |wd, block|
          wd2 = block.call(wd)
          unless wd2.is_a? Hash
            raise "Pre_create handler '#{block}' does not return hash, but '#{wd2}'"
          end
          wd2
        end
        self.new(wdescr)
      end

      attr_reader :widget

      def initialize(wdescr)
        debug  "Embedding widget - #{wdescr} "
        @wdescr = wdescr
        @widget = OMF::Web::Widget.create_widget(wdescr)
        debug "Created widget - #{@widget.class}"
      end

      def to_html
        content = @widget.content
        h = content.to_html
        klass = ['embedded']
        if caption = @wdescr[:caption] || @widget.title
          if mt = @wdescr[:'mime-type']
            klass << "embedded-#{mt.gsub('/', '-')}"
          end
          if ty = @wdescr[:type]
            klass << "embedded-#{ty.gsub('/', '-')}"
          end
          h += "<div class='caption'><span class='figure'>Figure: </span><span class='text'>#{caption}</span></div>"
        end
        root = ::REXML::Document.new("<div class='#{klass.join(' ')}'>#{h}</div>").root
        #puts "EMBEDDED >>> #{root}"
        root
      end

      def node_type
        :widget
      end
    end

    OpenMatch = /^\s*\{\{\{\s*(.*)$/
    CloseMatch = /(.*)\}\}\}/

    MaRuKu::In::Markdown::register_block_extension(
      :regexp  => OpenMatch,
      :handler => lambda { |doc, src, context|
        lines = []

        line = src.shift_line
        line =~ OpenMatch
        line = $1
        while line && !(line =~ CloseMatch)
          lines << line
          line = src.shift_line
        end
        lines << $1
        descr = YAML::load(lines.join("\n"))
        descr = OMF::Web::deep_symbolize_keys(descr)
        if (wdescr = descr[:widget])
          wel = WidgetElement.create(wdescr)
          context << wel
          (doc.attributes[:widgets] ||= []) << wel.widget
        else
          raise "Unknown embeddable '#{descr.inspect}'"
        end
        true
      }
    )

  end # module Maruku

end # OMF::Web::Widget::Text

if __FILE__ == $0
  OMF::Base::Loggable.init_log 'maruku'

  if fname = ARGV[0]
    content = File.open(fname).read
  else
    content = %{
# Lorem ipsum dolor sit

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin
sollicitudin nibh eu ligula lobortis ornare. Sed nibh nibh,
ullamcorper at vehicula ac, molestie ac nunc.

## Cras ut volutpat magna

Duis sodales, nisi vel pellentesque imperdiet, nisi massa accumsan
lorem, gravida scelerisque velit est vitae eros. Suspendisse eu
lacinia elit.
}
  end
  x = OMF::Web::Widget::Text::Maruku.format_content(content)
  puts x.to_html(suppress_section: false)
end
