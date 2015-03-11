
OML.require_dependency("vendor/nv_d3/js/nv.d3", ["vendor/d3/d3", "css!vendor/nv_d3/css/nv.d3"]);
OML.require_dependency("vendor/nv_d3/js/models/line", ["vendor/nv_d3/js/nv.d3"]);
OML.require_dependency("vendor/nv_d3/js/models/lineChart", ["vendor/nv_d3/js/models/line"]);

define(["graph/abstract_nv_chart",
          "graph/abstract_chart", "graph/axis",
          "css!graph_css/graph",
          "vendor/nv_d3/js/models/lineChart"
  ], function (abstract_nv_chart) {

  var line_chart3 = abstract_nv_chart.extend({
    decl_properties: [
      ['x_axis', 'key', {property: 'x'}],
      ['y_axis', 'key', {property: 'y'}],
      ['group_by', 'key', {optional: true}],
      ['stroke_width', 'int', 2],
      ['stroke_color', 'color', 'category10()'],
      ['stroke_fill', 'color', 'blue']
    ],


    _create_model: function() {
      return nv.models.lineChart();
    },

    _configure_mapping: function(m, chart) {
      var x_index = m.x_axis;
      var y_index = m.y_axis;
      chart.x(function(d) {
        var v = x_index(d);
        if (!_.isFinite(v)) {
          return 0;
        }
        return v;
      });
      chart.y(function(d) {
        var v = y_index(d);
        if (!_.isFinite(v)) {
          return 0;
        }
        return v;
      });
    },

    _configure_options: function(opts, chart) {
      line_chart3.__super__._configure_options.call(this, opts, chart);
      // chart
        // .rotateLabels(opts.rotate_labels)
        // .staggerLabels(opts.stagger_labels)
        // .tooltips(opts.tooltips)
        // .showValues(opts.show_values)
        // .margin(opts.margin)
        // ;
      this.opts.transition_duration = 0; // force no smooth transition
      this._configure_xy_axis(opts, chart);

      if (opts.pre_process) {
        switch(opts.pre_process) {
          case "relative_y":
            this.pre_process = function(data) {
              if (data.length <= 1) return data;

              var m = this.opts.mapping;
              var sx = this.schema[m.x_axis.property];
              var sy = this.schema[m.y_axis.property];
              if (sx == undefined || sy == undefined) {
                error("Can't resolve x_axis or y_axis mapping");
                return data;
              }
              var ix = sx.index;
              var iy = sy.index;

              var first = data.shift();
              var x0 = first[ix];
              var y0 = first[iy];
              _.each(data, function(d) {
                var x1 = d[ix];
                var y1 = d[iy];
                var dx = x1 - x0;
                if (dx != 0) {
                  var dy = y1 - y0;
                  d[iy] = dy / dx;
                } else {
                  // TODO: What's a better strategy?
                  var i = 0;
                }
                x0 = x1;
                y0 = y1;
              });
              return data;
            }
            break;
          default:
            error("Unknown pre_process method '" + opts.pre_process + "'.");
        }
      }
    },

    _datum: function(data, chart) {
      var self = this;
      var m = this.mapping;
      var o = this.opts;


      var group_by = m.group_by;
      var data;
      if (group_by != null) {
        data = this.group_by(data, group_by);
      } else {
        data = [data];
      };
      if (this.pre_process) {
        data = _.map(data, function(group) {
          return self.pre_process(group);
        });
      }

      chart.showLegend(group_by != null);

      return data.map(function(rows, i) {
        var name = m.group_by != null ? m.group_by(rows[0]) : 'unknown';
        var line = {
          values: rows,
          key: name,
        };
        if (o.area) line.area = o.area;
        if (m.stroke_color) {
          line.color = m.stroke_color(name);
        }
        if (m.stroke_width) {
          if (typeof(m.stroke_width) === 'function') {
            line.stroke_width = m.stroke_width(name);
          } else {
            line.stroke_width = m.stroke_width;
          }
        }
        return line;
      });
    },
  });

  return line_chart3;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/
