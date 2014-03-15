require 'omf-web/widget/abstract_widget'
require 'omf-web/data_source_proxy'

module OMF::Web::Widget

  # Supports widgets which visualize the content of a +Table+
  # which may also dynamically change.
  #
  class DataWidget < AbstractWidget
    #depends_on :css, "/resource/css/graph.css"

    attr_reader :name, :opts #:base_id


    # opts
    #   :data_sources .. Either a single table, or a hash of 'name' => table.
    #   :js_class .. Javascript class used for visualizing data
    #   :wopts .. options sent to the javascript instance
    #   :js_url .. URL where +jsVizClass+ can be loaded from
    #   :dynamic .. update the widget when the data_table is changing
    #     :updateInterval .. if web sockets aren't used, check every :updateInterval sec [3]
    #
    def initialize(opts = {})
      opts = opts.dup # not sure why we may need to this. Is this hash used anywhere wlse?
      unless vizType = opts[:type].split('/')[-1]
        raise "Missing widget option ':viz_type' for widget '#{name}' (#{opts.inspect})"
      end
      name = opts[:name] ||= 'Unknown'
      opts[:js_module] = "graph/#{vizType}"
      opts[:js_url] = "graph/js/#{vizType}.js"
      opts[:js_class] = "OML.#{vizType}"
      opts[:base_el] = "\##{dom_id}"
      super opts

      if (ds = opts.delete(:data_source))
        # single source
        data_sources = {:default => ds}
      end
      unless data_sources ||= opts.delete(:data_sources)
        raise "Missing option ':data_sources' for widget '#{name}'"
      end
      unless data_sources.kind_of? Hash
        data_sources = {:default => data_sources}
      end
      opts[:data_sources] = data_sources.collect do |name, ds_descr|
        unless ds_descr.is_a? Hash
          ds_descr = {:name => ds_descr}
        end
        ds_descr[:alias] = "#{name}_#{self.object_id}"
        #{:stream => ds_descr, :name => name}
        unless OMF::Web::DataSourceProxy.validate_ds_description(ds_descr)
          raise "Unknown data source requested for data widget - #{ds_descr}"
        end
        ds_descr
      end
      #puts "DTA_WIDGTE>>> #{opts[:data_sources].inspect}"
    end

    # This is the DOM id which should be used by the renderer for this widget.
    # We need to keep this here as various renderes at various levels may need
    # to get a reference to it to allow for such functionalities as
    # hiding, stacking, ...
    def dom_id
      "w#{object_id.abs}"
    end

    def content()
      OMF::Web::Theme.require 'data_renderer'
      OMF::Web::Theme::DataRenderer.new(self, @opts)
    end

    def collect_data_sources(ds_set)
      @opts[:data_sources].each do |ds|
        #ds_set.add(ds[:id] || ds[:name] || ds[:stream])
        ds_set.add(ds)
      end
      ds_set
    end
  end # DataWidget

end
