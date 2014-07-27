

require 'rack/websocket'
require 'omf_base/lobject'
require 'omf-web/session_store'
require 'thread'

module OMF::Web::Rack

  class WebsocketHandler < ::Rack::WebSocket::Application
    include OMF::Base::Loggable
    extend OMF::Base::Loggable

    MESSAGE_DELAY = 0.5 # Delay in pushing action message to browser
                        # after receiving a 'on_change' from monitored data proxy

    def on_open(env)
      #puts ">>>>> OPEN"
    end

    def on_message(env, msg_s)
      begin
        req = ::Rack::Request.new(env)
        sid = req.params['sid']
        Thread.current["sessionID"] = sid

        msg = JSON.parse(msg_s)
        debug("Msg(#{sid}): #{msg.inspect}")
        msg_type = msg['type']
        args = msg['args']
        msg_handler = "on_#{msg_type}".to_sym
        unless respond_to? msg_handler
          warn "Received unknonw request '#{msg_type}'"
          send_data({type: 'reply', status: 'error', err_msg: "Unknown message type '#{msg_type}'"}.to_json)
          return
        end
        context = OMF::Web::SessionStore[args['name'], :ws] ||= {}
        send(msg_handler, args, context)
      rescue Exception => ex
        error ex
        debug "#{ex.backtrace.join("\n")}"
        send_data({type: 'reply', status: 'exception', err_msg: ex.to_s}.to_json)
      end
    end

    def on_close(env)
      begin
        debug "client disconnected"
        @tab_inst.on_ws_close(self, @sub_path) if @tab_inst
        @tab_inst = nil
      rescue Exception => ex
        error(ex)
      end
    end

    def on_register_data_source(args, context)
      dsp = find_data_source(args)
      return unless dsp  # should define appropriate exception
      debug "Received registration for datasource proxy '#{dsp}'"
      send_data({type: 'reply', status: 'ok'}.to_json)

      mutex = Mutex.new
      semaphore = ConditionVariable.new
      action_queue = {}

      dsp.on_changed(args['offset']) do |action, rows|
        mutex.synchronize do
          (action_queue[action] ||= []).concat(rows)
          semaphore.signal
        end
      end

      # Send the rows in a separate thread, waiting a bit after the first one arriving
      # to 'bunch' things into more manageable number of messages
      Thread.new do
        begin
          loop do
            # Now lets send them
            mutex.synchronize do
              action_queue.each do |action, rows|
                next if rows.empty?
                debug "Sending '#{action}' message with #{rows.length} rows"
                msg = {
                  type: 'datasource_update',
                  datasource: dsp.name,
                  rows: rows,
                  action: action
                  #offset: offset
                }
                # http://stackoverflow.com/questions/17022394/convert-string-to-utf8-in-ruby
                send_data(msg.to_json.encode("iso-8859-1").force_encoding("UTF-8"))
                rows.clear
              end

              # wait until there is more to send
              semaphore.wait(mutex)
            end

            # OK, there is something to do, but let's wait a bit, maybe there is more
            sleep MESSAGE_DELAY
          end
        rescue Exception => ex
          error "on_register_data_source - #{ex}"
          debug "#{ex.backtrace.join("\n")}"
        end
      end

    end

    # args {"slice"=>{"col_name"=>"id", "col_value"=>"e8..."}, "ds_name"=>"individual_link"}}
    def on_request_slice(args, context)
      dsp = find_data_source(args)
      return unless dsp  # should define appropriate exception

      sargs = args['slice']
      col_name = sargs['col_name']
      col_value = sargs['col_value']
      debug "Creating slice '#{col_name}:#{col_value}' data source '#{dsp}'"

      if old_sdsp = context[:sliced_datasource]
        return if old_sdsp[:column_name] == col_name
        old_sdsp[:dsp].release
      end
      sdsp = dsp.create_slice(col_name, col_value)
      context[:sliced_datasource] = {:col_name => col_name, :dsp => sdsp}
      sdsp.on_changed(0) do |action, rows|
        msg = {
          type: 'datasource_update',
          datasource: args['ds_name'],
          rows: rows,
          action: action
          #offset: offset
        }
        send_data(msg.to_json.force_encoding("UTF-8"))
#
        # do |new_rows, offset|
        # msg = {
          # type: 'datasource_update',
          # datasource: args['ds_name'],
          # rows: new_rows,
          # offset: offset
        # }
        # send_data(msg.to_json)
      end
    end

    def find_data_source(args)
      ds_name = args['ds_name']
      unless dsp = OMF::Web::DataSourceProxy[ds_name]
        warn "Request for unknown datasource '#{ds_name}'."
        send_data({type: 'reply', status: 'error', err_msg: "Unknown datasource '#{ds_name}'"}.to_json)
        return nil
      end
      dsp
    end

  end # WebsocketHandler

end # module
