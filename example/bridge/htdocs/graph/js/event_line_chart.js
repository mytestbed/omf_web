
L.provide('OML.event_line_chart', ["graph/js/line_chart3", "#OML.line_chart3"], function () {

  OML.event_line_chart  = OML.line_chart3.extend({
    defaults: function() {
      return this.deep_defaults({
      }, OML.event_line_chart .__super__.defaults.call(this));      
    },    
    
    base_css_class: 'oml-event-line-chart',
    
    initialize: function(opts) {
      OML.event_line_chart.__super__.initialize.call(this, opts);
      
      var self = this;
      OHUB.bind("bridge.event_selected", function(evt) {
        self.event_id = evt.event[evt.schema.eventID.index];
        self.joint_id = evt.event[evt.schema.jointID.index];
        self.update();
      });
    },
    
    update: function() {
      var eid = this.event_id
      if (! eid) return;
      
      var data;
      if ((data = this.data_source.rows()) == null) {
        throw "Missing events array in data source"
      }
      
      data = _.filter(data, function(r) {
        return r[5] == eid;
      })
      if (data.length == 0) return;
      this.redraw(data);
      
      var i = 0;
    },

    
  }) // end of event-line_chart
}) // end of provide
