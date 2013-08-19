require 'omf-web/theme/abstract_page'
require 'omf-web/rack/session_authenticator'

module OMF::Web::Theme
  class Page < OMF::Web::Theme::AbstractPage

    depends_on :css, '/resource/theme/bright/css/reset-fonts-grids.css'
    depends_on :css, "/resource/theme/bright/css/bright.css"

    depends_on :script, %{
      OML.session_id = '#{Thread.current["sessionID"]}'
      OML.show_widget = function(opts) {
        var prefix = opts.inner_class;
        var index = opts.index;
        var widget_id = opts.widget_id;

        $('.' + prefix).hide();
        $('#' + prefix + '_' + index).show();

        var current = $('#' + prefix + '_l_' + index);
        current.addClass('current');
        current.siblings().removeClass('current');

        // May be a bit overkill, but this should shake out the widgets hidden so far
        OHUB.trigger('layout.resize', {});

        return false;
      };
    }

    # def initialize(widget, opts)
      # super
    # end

    def content
      super
      @renderer = @widget.content
      div :id => 'doc3' do
        if @renderer.render? :header
          div :id => 'hd' do
            if @renderer.render? :top_line
              render_top_line
            end
            if @renderer.render? :title
              render_title
            end
          end
        end
        div :id => 'bd' do
          render_body
        end
        if @renderer.render? :footer
          div :id => 'ft' do
            render_footer
          end
        end
      end
    end

    def render_top_line
      div :id => :top_line do
        render_tab_menu
        render_tools_menu
      end
    end

    def render_tab_menu
      ol :id => :tab_menu do
        @tabs.each do |h|
          lopts = h[:id] == @tab ? {:class => :current} : {}
          li lopts do
            #a :href => "#{@prefix}/#{h[:id]}?sid=#{Thread.current["sessionID"]}" do
            a :href => "#{@prefix}/#{h[:id]}" do
              span h[:name], :class => :tab_text
            end
          end
        end
      end
    end

    # def render_tools_menu
      # div :id => :tools_menu do
        # render_authentication
      # end
    # end

    def render_tools_menu
      ol :id => :tools_menu do
        render_tools_menu_authenticate
      end
    end

    def render_tools_menu_authenticate
      if user = OMF::Web::Rack::SessionAuthenticator.user()
        puts "USER>>>>> #{user}"
        li do
          a href: '#', class: 'user' do
            i class: "icon-user icon-white"
            text user[:name]
          end
        end
        li id: 'logout_li' do
          a id: 'logout_a', href: '#', class: 'logout' do
            i class: "icon-off icon-white"
            text 'Log out'
          end
        end
        am = "render_tools_menu_authenticate_#{user[:method]}".to_sym
        puts "METHOD>>>>> #{am}"
        if respond_to?(am)
          send(am, user)
        else
          javascript %{
            $('#logout_a').href = '/auth/logout'
          }
        end
      end
    end

    def render_tools_menu_authenticate_persona(user)
      javascript %{
        $('#logout_li').hide();
        $.getScript("https://login.persona.org/include.js")
          .done(function(script, textStatus) {
            $('#logout_li').show();
            $('#logout_a').click(function() {
              navigator.id.logout();
            })
            navigator.id.watch({
              loggedInUser: '#{user}',
              onlogin: function(assertion) {},
              onlogout: function() {
                $.ajax({
                  type: 'POST',
                  url: '/auth/logout',
                  success: function(res, status, xhr) {
                    window.location = '/';
                  },
                  error: function(xhr, status, err) { alert("Logout failure: " + err); }
                });
              }
            })
          });
      }
    end

    def render_title
      h1 @page_title || 'Missing :page_title'
    end

    def render_body
      render_flash
      render_card_body
    end

    def render_card_body
      return unless @widget
      Thread.current["top_renderer"] = self
      rawtext @renderer.to_html
    end

    def render_footer
      if @footer_right.is_a? Proc
        widget(Erector.inline(&@footer_right))
      else
        span :style => 'float:right;margin-right:10pt' do
          text @footer_right || "omf-web V#{OMF::Web::VERSION}"
        end
      end
      if @footer_left.is_a? Proc
        widget(Erector.inline(&@footer_left))
      else
        text @footer_left || 'Brought to you by the TEMPO Team'
      end

    end




  end # class Page
end # OMF::Web::Theme