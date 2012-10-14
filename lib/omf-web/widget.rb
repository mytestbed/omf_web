
require 'erector'

module OMF::Web::Widget
  
    
    @@widgets = {}
    @@descriptions = {}  
    @@type2class = {}  
    
    def self.register_widget(wdescr)
      unless id = wdescr[:id]
        raise "Missing 'id' for widget '#{wdescr.inspect}'"
      end
      id = id.to_sym
      if (@@descriptions.key? id)
        raise "Repeated try to register widget '#{id}'"
      end  
      @@descriptions[id] = wdescr
    end
    
    def self.registered_widgets()
      @@descriptions
    end
    
    def self.register_widget_type(id, widget_class)
      id = id.to_sym
      if (@@type2class.key? id)
        raise "Repeated try to register widget type '#{id}'"
      end  
      @@type2class[id] = widget_class
    end
    
    
    # Return the number of top level widgets. If 'restrict_to' is an
    # array, only return those. 
    #
    def self.toplevel_widgets(restrict_to = nil)
      if restrict_to
        wa = restrict_to.map do |name|
          unless w = @@descriptions[name.to_sym]
            raise "Unknown top level widget '#{name}'"
          end
          w
        end
      else
        wa = @@descriptions.map do |id, w|
          w[:top_level] ? w : nil
        end.compact
      end
      wa.sort do |a, b|
        (b[:priority] || 100) <=> (a[:priority] || 100) 
      end
    end    
    
    def self.create_widget(name)
      if name.is_a? Array
        # this is  short notation for a stacked widget
        #
        wdescr = { :type => 'layout/stacked', :widgets => name} 
      elsif name.is_a? Hash
        wdescr = name
      else
        unless wdescr = @@descriptions[name.to_sym]
          raise "Can't create unknown widget '#{name}':(#{@@descriptions.keys.inspect})"
        end
      end
      # Let's check if this actually extends another widget description
      if (id_ref = wdescr[:id_ref])
        unless wd = @@descriptions[id_ref.to_sym]
          raise "Can't find referenced widget '#{id_ref}':(#{@@descriptions.keys.inspect})"
        end
        wdescr = wd.dup.merge(wdescr) # TODO: This should really be a DEEP copy and merge
        wdescr.delete(:id_ref)
      end
      unless wdescr.key? :id
        wdescr[:id] = "wid_#{wdescr.object_id}"
      end
      if w = @@widgets[wdescr[:id]]
        return w
      end
      case type = (wdescr[:type] || wdescr['type']).to_s
      when /^data/
        require 'omf-web/widget/data_widget'
        w = OMF::Web::Widget::DataWidget.new(wdescr)
      when /^layout/
        require 'omf-web/widget/layout'
        w =  OMF::Web::Widget::Layout.create_layout_widget(type, wdescr)        
      when /^text/
        require 'omf-web/widget/text/text_widget'
        w =  OMF::Web::Widget::TextWidget.create_text_widget(type, wdescr)        
      when /^code/
        require 'omf-web/widget/code_widget'
        w =  OMF::Web::Widget::CodeWidget.create_code_widget(type, wdescr)        
      when /^moustache/
        require 'omf-web/widget/mustache_widget'
        w =  OMF::Web::Widget::MustacheWidget.create_mustache_widget(type, wdescr)        
      else
        raise "Unknown widget type '#{type}' (#{wdescr.inspect})"
      end
      @@widgets[wdescr[:id]] = w
    end
    
    def self._init()
      register_widget
    end
  

end # OMF::Web::Widget