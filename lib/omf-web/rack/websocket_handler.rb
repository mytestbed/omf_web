
require 'rack/websocket'
require 'omf_common/lobject'
require 'omf-web/session_store'

module OMF::Web::Rack
  
  class WebsocketHandler < ::Rack::WebSocket::Application
    include OMF::Common::Loggable
    extend OMF::Common::Loggable    
  
    def on_message(env, msg_s)
      begin
        req = ::Rack::Request.new(env)
        sid = req.params['sid']
        Thread.current["sessionID"] = sid

        msg = JSON.parse(msg_s)
        debug("Msg(#{sid}): #{msg.inspect}")
        msg_type = msg['type']
        args = msg['args']
        case msg_type
        when 'register_data_source'
          ds_name = args['name']
          unless dsp = OMF::Web::DataSourceProxy[ds_name]
            send_data({type: 'reply', status: 'error', err_msg: "Unknown datasource '#{ds_name}'"}.to_json)
            return
          end
          debug "Received registration for datasource proxy '#{dsp}'"
          dsp.on_changed(args['offset']) do |new_rows, offset|
            msg = {
              type: 'datasource_update',
              datasource: ds_name,
              rows: new_rows,
              offset: offset
            }
            send_data(msg.to_json)
          end
          send_data({type: 'reply', status: 'ok'}.to_json)
        else
          send_data({type: 'reply', status: 'error', err_msg: "Unknown message type '#{msg_type}'"}.to_json)
        end
      rescue Exception => ex
        error ex
        debug "#{ex.backtrace.join("\n")}"
        send_data({type: 'reply', status: 'exception', err_msg: ex.to_s}.to_json)
      end
      #puts "message processed"      
    end
  
    def on_close(env)
      begin
        puts "client disconnected"
        @tab_inst.on_ws_close(self, @sub_path) if @tab_inst
        @tab_inst = nil
      rescue Exception => ex
        error(ex)
      end
    end

  end # WebsocketHandler
  
end # module