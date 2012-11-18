
require 'omf-web/widget/abstract_widget'
require 'omf-web/content/repository'

module OMF::Web::Widget
  
  # Maintains the context for a particular code rendering within a specific session.
  #
  class CodeWidget < AbstractWidget
    
    def self.create_code_widget(type, wdescr)
      return self.new(wdescr)
    end
    
    attr_accessor :content_proxy
    
    def initialize(opts)
      super opts
      unless (content_descr = opts[:content])
        raise "Missing 'content' option in '#{opts.describe}'"
      end  
      @content_proxy = OMF::Web::ContentRepository.create_content_proxy_for(content_descr, opts)
    end
    
    def title 
      @content_proxy.name
    end
    
    def mime_type
      @content_proxy.mime_type
    end
    
    def update_url
      @content_proxy.content_url
    end
 
    def content_id
      @content_proxy.content_id
    end
   
    def content()
      OMF::Web::Theme.require 'code_renderer'
      mode = @content_proxy.mime_type.split('/')[-1]
      OMF::Web::Theme::CodeRenderer.new(self, @content_proxy.content, mode, @opts)
    end
    
    def collect_data_sources(ds_set)
      ds_set
    end
    
  
    # @@codeType2mime = {
      # :ruby => '/text/ruby',
      # :xml => '/text/xml'
    # }
    
    # def render_code(source)
      # content = load_content(source)
      # type = code_type(source)
      # mimeType = @@codeType2mime[type]
#       
      # begin
        # CodeRay.scan content, type
        # #tokens.html :line_numbers => :inline, :tab_width => 2, :wrap => :div
      # rescue Exception => ex
        # error ex
        # debug ex.backtrace.join("\n")
      # end
    # end
    
    # def load_content(source)
      # unless File.readable?(source)
        # raise "Cannot read text file '#{source}'"
      # end
      # content = File.open(source).read
    # end
        
    # Return the language the code is written in 
    #
    def code_type(source)
      if source.end_with? '.rb'
        :ruby
      elsif source.end_with? '.xml'
        :xml
      else
        :text
      end
    end
    
    
  end # CodeWidget
  
end
