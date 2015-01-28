
require 'omf-web/version'

module OMF
  module Web
    module Tab; end
    module Rack; end
    module Widget; end

    class OMFWebException < Exception; end

    #VERSION = 'git:release-5.4'

    def self.start(opts, &block)
      require 'omf-web/thin/runner'

      if layout = opts.delete(:layout)
        load_widget_from_file(layout)
      end

      #Thin::Logging.debug = true
      runner = OMF::Web::Runner.new(ARGV, opts)
      block.call if block
      runner.run!
    end

    #@@datasources = {}
    #@@widgets = {}

    def self.register_datasource(data_source, opts = {})
      require 'omf-web/data_source_proxy'
      OMF::Web::DataSourceProxy.register_datasource(data_source, opts)

    end

    def self.register_widget(widget_descr)
      require 'omf-web/widget'
      wdescr = deep_symbolize_keys widget_descr
      OMF::Web::Widget.register_widget(wdescr)
    end

    def self.load_widget_from_file(file_name)
      require 'yaml'
      y = YAML.load_file(file_name)
      if w = y['widget']
        OMF::Web.register_widget w
      else
        OMF::Base::LObject.error "Doesn't seem to be a widget definition. Expected 'widget' but found '#{y.keys.join(', ')}'"
      end
    end

    def self.use_tab(tab_id)
      OMF::Web::Tab.use_tab tab_id.to_sym
    end

    private

    # Taken from active_support
    #
    def self.deep_symbolize_keys(obj)
      if obj.is_a? Hash
        obj.inject({}) do |result, (key, value)|
          if value.is_a?(Hash) || value.is_a?(Array)
            value = deep_symbolize_keys(value)
          end
          result[(key.to_sym rescue key) || key] = value
          result
        end
      elsif obj.is_a? Array
        obj.collect { |e| deep_symbolize_keys(e) }
      else
        obj
      end
    end


  end
end


