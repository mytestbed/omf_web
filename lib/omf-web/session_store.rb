
require 'omf_base/lobject'


module OMF::Web

  # Keeps session state.
  #
  # TODO: Implement cleanup thread
  #
  class SessionStore < OMF::Base::LObject
    @@sessions = {}

    def self.[](key, domain)
      self.session["#{domain}:#{key}"]
    end

    def self.[]=(key, domain, value)
      self.session["#{domain}:#{key}"] = value
    end

    def self.session()
      sid = session_id
      session = @@sessions[sid] ||= {:content => {}}
      #puts "STORE>> #{sid} = #{session[:content].keys.inspect}"
      session[:ts] = Time.now
      session[:content]
    end

    def self.session_id
      sid = Thread.current["sessionID"]
      raise "Missing session id 'sid'" if sid.nil?
      sid
    end

    def self.find_tab_from_path(comp_path)
      sid = comp_path.shift
      unless session = self.session(sid)
        raise "Can't find session '#{sid}', may have timed out"
      end
      tid = comp_path.shift.to_sym
      unless tab_inst = session[tid]
        raise "Can't find tab '#{tid}'"
      end
      {:sid => sid, :tab_inst => tab_inst, :sub_path => comp_path}
    end

    def self.find_across_sessions(&block)
      @@sessions.values.map { |v| v[:content] }.find(&block)
    end

    # Return a session context which will execute block given to
    # #call in this session context
    #
    def self.session_context
      SessionContext.new
    end
  end # SessionStore

  class SessionContext
    def initialize
      @sid = Thread.current["sessionID"]
    end

    def call(&block)
      begin
        current_sid = Thread.current["sessionID"]
        Thread.current["sessionID"] = @sid
        block.call
      ensure
        Thread.current["sessionID"] = current_sid
      end
    end
  end

end # OMF:Web




