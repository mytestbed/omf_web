define(["graph/abstract_nv_chart"], function (abstract_nv_chart) {

  var multi_barchart = abstract_nv_chart.extend({

    decl_properties: [
      ['label', 'key', {property: 'label'}],
      ['value', 'key', {property: 'value'}],
      ['group_by', 'key', {property: 'id', optional: true}],
      ['fill_color', 'color', 'category10()'],
    ],

    defaults: function() {
      return this.deep_defaults({
        bins: null, // number of bins to use. The default bin function will
                  // divide the values into uniform bins using Sturges' formula.
        rotate_labels: -45,
        tooltips: true,
        show_legend: true,
        show_controls: true,
        // reduceXTicks
        // showControls
        // stacked',
        // delay

        margin: {
          top: 20, right: 0, bottom: 50, left: 80
        }
      }, multi_barchart.__super__.defaults.call(this));
    },

    _create_model: function() {
      return  nv.models.multiBarChart();
    },

    _configure_mapping: function(m, chart) {
      var label_f = m.label;
      var value_f = m.value;
      chart.x(function(d) {
        var v = label_f(d);
        return v;
      });
      chart.y(function(d) {
        var v = value_f(d);
        return v;
      });
    },

    _configure_options: function(opts, chart) {
      multi_barchart.__super__._configure_options.call(this, opts, chart);
      chart
        .rotateLabels(opts.rotate_labels)
        .tooltips(opts.tooltips)
        .showLegend(opts.show_legend)
        .showControls(opts.show_control)
        .margin(opts.margin)
        ;
      this._configure_xy_axis(opts, chart);
    },

    _datum: function(data, chart) {
      var o = this.opts;
      var m = this.mapping;

      var group_by = m.group_by;
      var value_f = m.value;
      var values, labels;
      if (group_by != null) {
        values = _.map(this.group_by(data, group_by), value_f);
        labels =
        datum = _.map(this.group_by(data, group_by), function(gdata) {
          var values = _.map(gdata, value_f);
          return {
            key: group_by(gdata[0]),
            values: values
          };
        });
      } else {
        datum = [{
          key: '???',
          values: data
        }];
      }

      if (o.show_legend) chart.showLegend(datum.length > 1);
      if (o.show_controls) chart.showControls(datum.length > 1);

      return datum;
    },

  });

  return multi_barchart;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/