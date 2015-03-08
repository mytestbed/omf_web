
//OML.append_require({shim: {"vendor/nv_d3/js/nv.d3": {deps: ["vendor/d3/d3", "css!vendor/nv_d3/css/nv.d3"]}}});
OML.append_require_shim("vendor/nv_d3/js/nv.d3", {deps: ["vendor/d3/d3", "css!vendor/nv_d3/css/nv.d3"]});

define(["graph/abstract_chart", 'vendor/nv_d3/js/nv.d3'], function (abstract_chart) {

  var abstract_nv_chart = abstract_chart.extend({
    axis_defaults: {
      legend: {
        text: 'DESCRIBE ME',
        offset: 40
      },
      ticks: {
        // type: 'date',
        // format: '%I:%M', // hour:minutes
        format: ',.3s',
        // format: ",.0f" // integers with comma-grouping for thousands.
        //subdivide: 2, // the number of uniform subdivisions to make between major tick marks
        //size: [8, 4, 16], // set the size of major, minor and end ticks
        //padding: 20, // the padding between ticks and tick labels
        //count: 2 // number of ticks to display - this is currently overridden in NV
      },
      margin: {
        top: 0, right: 0, bottom: 0, left: 50 // not sure what impact this really has?
      }
    },

    defaults: function() {
      return this.deep_defaults({
        transition_duration: 500
      }, abstract_nv_chart.__super__.defaults.call(this));
    },


    configure_base_layer: function(vis) {
      this.base_layer = vis;
      this._configure_options(this.opts, this.get_chart());
    },

    get_chart: function() {
      if (! this.chart) {
        this.chart = this._create_model(); //nv.models.lineWithFocusChart();
      }
      return this.chart;
    },

    init_mapping: function() {
      this._configure_mapping(this.mapping, this.get_chart());
    },

    _configure_mapping: function(m, chart) {
    },

    _configure_options: function(opts, chart) {
      chart.margin(opts.margin);
    },

    _configure_xy_axis: function(opts, chart) {
      var oaxis = opts.axis || {};
      var a_defaults = this.axis_defaults;

      var xao = _.defaults(oaxis.x || {}, a_defaults);
      this._configure_axis('x', chart.xAxis, xao);
      var yao = _.defaults(oaxis.y || {}, a_defaults);
      this._configure_axis('y', chart.yAxis, yao);
    },

    _configure_axis: function(name, axis, opts) {
      // LABEL
      var ol = opts.legend;
      if (ol) {
        var ol = ol ? (typeof(ol) === "string" ? {text: ol} : ol) : {};
        //ol = _.defaults(ol, defaults.axis);
        axis.axisLabel(ol.text);
      }

      // TICKS
      var ot = opts.ticks; // _.defaults(opts.ticks || {}, defaults.ticks);
      // Check if we need a special formatter for the tick labels
      if (ot.type == 'date' || ot.type == 'dateTime') {
        var d_f = d3.time.format(ot.format || "%X");
        axis.tickFormat(function(d) {
          var date = new Date(1000 * d);  // TODO: Implicitly assuming that value is in seconds is most likely NOT a good idea
          var fs = d_f(date);
          return fs;
        });
      } else if (ot.type == 'key') {
        var lm = ot.key_map;
        axis.tickFormat(function(d) {
          var l = lm[d] || ('??-' + d);
          return l;
        });
      } else if (ot.format) {
        axis.tickFormat(d3.format(ot.format));
      }
      if (ot.subdivide) axis.tickSubdivide(ot.subdivide);
      if (ot.size) {
        // apply doesn't seem to work here
        if (typeof ot.size === 'number')
          axis.tickSize(ot.size);
        else {
          var a = ot.size;
          switch (a.length) {
            case 1: axis.tickSize(a[0]); break;
            case 2: axis.tickSize(a[0], a[1]); break;
            case 3: axis.tickSize(a[0], a[1], a[2]); break;
          }
        }
      }
      if (ot.padding) axis.tickPadding(ot.padding);
      if (ot.count) axis.ticks(ot.count);

      // MARGIN
      var om = opts.margin; //_.defaults(ot.margin || {}, defaults.margin);
      axis.margin(om);

      // MISC
      axis.showMaxMin(false);
    },

    resize: function() {
      var self = this;
      abstract_nv_chart.__super__.resize.call(this);
      if (this.chart) {
        // this.chart.width(self.width);
        // this.chart.height(self.height);
        this.chart.width(self.w);
        this.chart.height(self.h);
        this.update();
      }
    },

    redraw: function(data) {
      if (! data || !this.base_layer) return;
      var m = this.opts.margin;
      var aw = this.w - m.left - m.right;
      var ah = this.h - m.top - m.bottom;
      if (aw < 10 || ah < 10) {
        return;
      }
      var bl = this.base_layer//.select(".chart_layer")
                  .datum(this._datum(data, this.chart))
                  ;
      if (this.opts.transition_duration > 0) {
        bl = bl.transition().duration(500);
      }
      bl.call(this.chart);
    },

  });

  return abstract_nv_chart;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
