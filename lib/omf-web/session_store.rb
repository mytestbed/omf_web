
require 'omf_common/lobject'


module OMF::Web
        
  # Keeps session state.
  #
  # TODO: Implement cleanup thread
  #
  class SessionStore < OMF::Common::LObject
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
      unless sid
        raise "Missing session id 'sid'"
      end
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
  end # SessionStore

end # OMF:Web


      
        
