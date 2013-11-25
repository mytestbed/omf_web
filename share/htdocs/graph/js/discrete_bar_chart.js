
define(["graph/abstract_nv_chart"], function (abstract_nv_chart) {

  var discrete_bar_chart = abstract_nv_chart.extend({
    decl_properties: [
      ['label', 'key', {property: 'label'}],
      ['value', 'key', {property: 'value'}],
    ],

    defaults: function() {
      return this.deep_defaults({
        rotate_labels: -45,
        stagger_labels: true,
        //.staggerLabels(historicalBarChart[0].values.length > 8)
        tooltips: true,
        show_values: true,
        margin: {
          top: 20, right: 0, bottom: 50, left: 80
        }
      }, discrete_bar_chart.__super__.defaults.call(this));
    },

    _create_model: function() {
      return  nv.models.discreteBarChart();
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
      discrete_bar_chart.__super__._configure_options.call(this, opts, chart);
      chart
        //.rotateLabels(opts.rotate_labels)
        .staggerLabels(opts.stagger_labels)
        .tooltips(opts.tooltips)
        .showValues(opts.show_values)
        .margin(opts.margin)
        ;
      this._configure_all_axis(opts, chart);
    },

    _configure_all_axis: function(opts, chart) {
      var oaxis = opts.axis || {};
      var a_defaults = this.axis_defaults;

      // var xao = _.defaults(oaxis.x || {}, a_defaults);
      // this._configure_axis('x', chart.xAxis, xao);
      var yao = _.defaults(oaxis.y || {}, a_defaults);
      this._configure_axis('y', chart.yAxis, yao);
    },

    _datum: function(data, chart) {
      return [{
                key: "???",
                values: data
              }];
    }

  });

  return discrete_bar_chart;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/