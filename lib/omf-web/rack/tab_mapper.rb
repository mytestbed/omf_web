
require 'omf_common/lobject'
#require 'erector'
require 'rack'
#require 'omf-web/page'
#require 'omf-web/multi_file'
require 'omf-web/session_store'
#require 'omf-web/tab'
require 'omf-web/widget'
require 'omf-web/theme'

      
module OMF::Web::Rack      
  class TabMapper < OMF::Common::LObject
    

    def initialize(opts = {})
      @opts = opts
      @tab_opts = opts[:tabs] || {}
      @tabs = {}
      find_tabs()
    end
    
    def find_tabs()
      tabs = OMF::Web::Widget.toplevel_widgets(@opts[:use_tabs])
      @enabled_tabs = {} 
      tabs.each do |t| 
        name = t[:id].to_sym
        @enabled_tabs[name] = t  
      end
      @opts[:tabs] = tabs
    end
    
    def call(env)
      #puts env.keys.inspect

      req = ::Rack::Request.new(env)
      #puts "COOKIES>>>> #{req.cookies.inspect}"
      #req.cookies['user'] = 'booo'
      
      # sessionID = req.params['sid']
      # if sessionID.nil? || sessionID.empty?
        # sessionID = "s#{(rand * 10000000).to_i}"
      # end
      # Thread.current["sessionID"] = sessionID
      
      OMF::Web::Theme.require 'page'      
      body, headers = render_page(req)
      if headers.kind_of? String
        headers = {"Content-Type" => headers}
      end
      [200, headers, [body]] # required for ruby > 1.9.2 
    end
    
    def _component_name(path)
      unless comp_name = path[1]
        comp_name = ((@opts[:tabs] || [])[0] || {})[:id]
      end
      comp_name = comp_name.to_sym if comp_name
      #puts "PATH: #{path} - #{comp_name}"
      comp_name
    end
    
    def render_card(req)
      #puts ">>>> REQ: #{req.path_info}::#{req.inspect}"
      
      opts = @opts.dup
      opts[:prefix] = req.script_name
      opts[:request] = req      
      opts[:path] = req.path_info

      path = req.path_info.split('/')
      unless comp_name = _component_name(path)
        return render_no_card(opts)
      end
      opts[:component_name] = comp_name.to_sym
      # action = (path[2] || 'show').to_sym

      tab = @enabled_tabs[comp_name]
      unless tab
        warn "Request for unknown component '#{comp_name.inspect}':(#{@enabled_tabs.keys.inspect})"
        return render_unknown_card(comp_name, opts)
      end
      opts[:tab] = tab_id = tab[:id]
      
      widget = find_top_widget(tab, req)
      OMF::Web::Theme.require 'page'
      page = OMF::Web::Theme::Page.new(widget, opts)
      [page.to_html, 'text/html']
    end
    
    
    def find_top_widget(tab, req)
      sid = req.params['sid']
      tab_id = tab[:id]
      @tabs[tab_id] ||= OMF::Web::Widget.create_widget(tab_id) 
      #inst = OMF::Web::SessionStore[tab_id, :tab] 
    end
    
    def render_unknown_card(comp_name, popts)
      #popts[:active_id] = 'unknown'
      popts[:flash] = {:alert => %{Unknonw component '#{comp_name}'. To select any of the available 
        components, please click on one of the tabs above.}}

      [OMF::Web::Theme::Page.new(nil, popts).to_html, 'text/html']
    end

    def render_no_card(popts)
      popts[:active_id] = 'unknown'
      popts[:flash] = {:alert => %{There are no components defined for this site.}}
      popts[:tabs] = []      
      [OMF::Web::Theme::Page.new(nil, popts).to_html, 'text/html']
    end
   
    def render_page(req)
      render_card(req)
    end
  
  end # Tab Mapper
  
end # OMF:Common::Web2


      
        
