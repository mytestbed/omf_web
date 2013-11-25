define(["graph/abstract_nv_chart"], function (abstract_nv_chart) {

  var pie_chart2 = abstract_nv_chart.extend({
    decl_properties: [
      ['label', 'key', {property: 'label'}],
      ['value', 'key', {property: 'value'}],
      ['color', 'color', 'category10()'],

    ],

    defaults: function() {
      return this.deep_defaults({
        tooltips: true,
        show_labels: true,
        donut: false,
        label_threshold: 0.02, //if slice percentage is under this, don't show label
        show_legend: true,

        margin: {
          top: 20, right: 0, bottom: 100, left: 50
        }
      }, pie_chart2.__super__.defaults.call(this));
    },

    _create_model: function() {
      return  nv.models.pieChart();
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
      chart.color(function(d, i) {
        // TODO: This is most likely broken. The color mapping
        // function should map from an element of 'd', not 'i'
        var v = m.color(i);
        return v;
      });
    },

    _configure_options: function(opts, chart) {
      pie_chart2.__super__._configure_options.call(this, opts, chart);
      chart
        .tooltips(opts.tooltips)
        .showLabels(opts.show_labels)
        .donut(opts.donut)
        .labelThreshold(opts.label_threshold)
        .showLegend(opts.show_legend)
        .margin(opts.margin)
        ;
    },

    _datum: function(data, chart) {
      return [{
                key: "???",
                values: data
              }];
    }

  });

  return pie_chart2;
});

/*
  Local Variables:
  mode: Javascript
  tab-width: 2
  indent-tabs-mode: nil
  End:
*/

