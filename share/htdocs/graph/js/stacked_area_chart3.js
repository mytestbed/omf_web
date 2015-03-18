
OML.require_dependency("vendor/nv_d3/js/nv.d3", ["vendor/d3/d3", "css!vendor/nv_d3/css/nv.d3"]);
OML.require_dependency("vendor/nv_d3/js/models/line", ["vendor/nv_d3/js/nv.d3"]);
OML.require_dependency("vendor/nv_d3/js/models/lineChart", ["vendor/nv_d3/js/models/line"]);

define(["graph/line_chart3",
  ], function (line_chart) {

  var klass = line_chart.extend({
    decl_properties: line_chart.prototype.decl_properties.concat([
    ]),

    // This product includes color specifications and designs developed by Cynthia Brewer (http://colorbrewer.org/).
    RdYlGr: {
      3: ["#fc8d59", "#ffffbf", "#91cf60"],
      4: ["#d7191c", "#fdae61", "#a6d96a", "#1a9641"],
      5: ["#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641"],
      6: ["#d73027", "#fc8d59", "#fee08b", "#d9ef8b", "#91cf60", "#1a9850"],
      7: ["#d73027", "#fc8d59", "#fee08b", "#ffffbf", "#d9ef8b", "#91cf60", "#1a9850"],
      8: ["#d73027", "#f46d43", "#fdae61", "#fee08b", "#d9ef8b", "#a6d96a", "#66bd63", "#1a9850"],
      9: ["#d73027", "#f46d43", "#fdae61", "#fee08b", "#ffffbf", "#d9ef8b", "#a6d96a", "#66bd63", "#1a9850"],
      10: ["#a50026", "#d73027", "#f46d43", "#fdae61", "#fee08b", "#d9ef8b", "#a6d96a", "#66bd63", "#1a9850", "#006837"],
      11: ["#a50026", "#d73027", "#f46d43", "#fdae61", "#fee08b", "#ffffbf", "#d9ef8b", "#a6d96a", "#66bd63", "#1a9850", "#006837"]
    },

    _create_model: function() {
      return nv.models.stackedAreaChart()
        .useInteractiveGuideline(true)
        .controlLabels({stacked: "Stacked"})
        .showControls(false)

        ;
    },

    _configure_options: function(opts, chart) {
      klass.__super__._configure_options.call(this, opts, chart);
      chart.stacked.style('expand');
      chart.useInteractiveGuideline(true);


      // chart
        // .rotateLabels(opts.rotate_labels)
        // .staggerLabels(opts.stagger_labels)
        // .tooltips(opts.tooltips)
        // .showValues(opts.show_values)
        // .margin(opts.margin)
        // ;
      //this.opts.transition_duration = 0; // force no smooth transition
      //this._configure_xy_axis(opts, chart);
    },

    _configure_mapping: function(m, chart) {

      chart.x(function(d) {
        return d[1].x;
      });
      chart.y(function(d) {
        var ya = d[1].y;
        var y = ya[d[0]];
        return y || 0;
      });
    },

    _bin_data: function(data) {
      if (data.length == 0) return null;

      var self = this;
      var m = self.mapping;
      var dxy = _.map(data, function(d) { return [m.x_axis(d), m.y_axis(d)]; });

      var unique_y = _.unique(dxy, function(d) { return d[1]; });
      var bin_f;
      var y_bin_labels;
      if (unique_y.length > 10) {

      } else {
        var centers = _.map(unique_y, function(d) { return d[1]; }).sort();
        y_bin_cnt = centers.length;
        var last = centers[0];
        var borders = _.map(centers.slice(1), function(c) {
          var m = (c - last) / 2 + last;
          last = c;
          return m;
        })
        var ccnt = borders.length;
        bin_f = function(d) {
          var y = d[1];
          for (var i = 0; i < ccnt; i++) {
            if (y <= borders[i]) return i;
          }
          return ccnt;
        }
        y_bin_labels = _.map(centers, function(d) { return "" + d; });
      }

      var min_x = m.x_axis(_.min(data, function(d) {
        return m.x_axis(d);
      }));
      var max_x = m.x_axis(_.max(data, function(d) { return m.x_axis(d); }));
      var x_bin_cnt = Math.round(self.w / 5);
      var x_bin_w = x_bin_cnt / (max_x - min_x); // make bins 5 smaple wide
      var inv_x_bin_w = 1 / x_bin_w;
      var x_bins = [];
      for (var i = 0; i < x_bin_cnt; i++) {
        x_bins[i] = {x: inv_x_bin_w * (0.5 + i) + min_x, y: []};
      }
      _.each(dxy, function(d) {
        var x = d[0];
        var xbid = Math.round((x - min_x) * x_bin_w);
        var bin = x_bins[xbid];
        if (bin == null) {
          bin = x_bins[xbid] = {x: inv_x_bin_w * (0.5 + xbid) + min_x, y: []}
        }
        var ybid = bin_f(d);
        var ycnt = bin.y[ybid] || 0;
        bin.y[ybid] = ycnt + 1;
      });
      return {x_bins: _.compact(x_bins), y_bin_labels: y_bin_labels};
    },

    _datum: function(data, chart) {
      var self = this;
      var m = this.mapping;
      var o = this.opts;

      var bd = this._bin_data(data);
      if (bd == null) return [];

      var x_bins = bd.x_bins;
      var y_bin_labels = bd.y_bin_labels;

      // Don't show legend if there are too many ines (groups)
      chart.showLegend(true);
      chart.color(this.RdYlGr[y_bin_labels.length]|| d3.scale.category20().range());
      var lines = [];
      for (var i = 0; i < y_bin_labels.length; i++) {
        var name = y_bin_labels[i];
        var line = {
          key: name,
          values: _.map(x_bins, function(b) { return[i, b]; })
        };
        lines.push(line);
      }
      return lines;
    },

  });

  return klass;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
