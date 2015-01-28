define(["graph/abstract_widget", "echarts"], 
  function(abstract_widget, ec) {
    var context = abstract_widget.extend({

      defaults: function() {
        return this.deep_defaults({
          margin: {
            left: 0,
            top:  0,
            right: 0,
            bottom: 0
          },
          crop: { // part of the chart canvas we want to crop
            left: 20,
            top:  30,
            right: 50,
            bottom: 20
          },
        }, context.__super__.defaults.call(this));
      },

      initialize: function (opts) {
        context.__super__.initialize.call(this, opts);
  
  
        //var vis = this.init_svg(this.w, this.h);
        //if (vis) this.configure_base_layer(vis);
  
        var self = this;
        //OHUB.bind("graph.highlighted", function(evt) {
        //  if (evt.source == self) return;
        //  self.on_highlighted(evt);
        //});
        //OHUB.bind("graph.dehighlighted", function(evt) {
        //  if (evt.source == self) return;
        //  self.on_dehighlighted(evt);
        //});
  
        this.init_chart();
        this.update();
      },

      configure_base_layer: function(vis) {
        //this.base_layer = vis;
        //this._configure_options(this.opts, this.get_chart());
      },

  
      init_chart: function() {
        var base_el = $(this.opts.base_el);
        var c = this.opts.crop;
        var m = this.opts.margin;

        var w = this.w - (m.left + m.right) + c.left + c.right;
        var h = this.h - (m.top + m.bottom) + c.top + c.bottom;

        var style = "position: relative; left: -" + c.left + "px; top: -" + c.top + "px; width: " + w + "px; height: " + h + "px;";
        var graph_layer = $("<div class='echarts-frame' style='" + style + "' />");
        base_el.append(graph_layer);
        this.echart = ec.init(graph_layer.get());
        var copts = this.get_chart_option()
        this.echart.setOption(copts);
      },

      update: function () {
        context.__super__.update.call(this);
      },

      redraw: function(data) {
        this._draw(data, this.echart);
      },

      ///////

      get_chart: function() {
        if (! this.chart) {
          this.chart = this._create_model(); //nv.models.lineWithFocusChart();
        }
        return this.chart;
      },

      init_mapping: function() {
        //this._configure_mapping(this.mapping, this.get_chart());
      },

      _create_model: function() {
        return nv.models.lineChart();
      },

      _configure_mapping: function(m, chart) {
        var x_index = m.x_axis;
        var y_index = m.y_axis;
        chart.x(function(d) {
          var v = x_index(d);
          return v;
        });
        chart.y(function(d) {
          var v = y_index(d);
          return v;
        });
      },



    });
  
    return context;
});