
L.provide('OML.event_table', ["graph/table2", "#OML.table2", [
                                '/resource/vendor/slickgrid/plugins/slick.checkboxselectcolumn.js'
                             ]], function () {

  OML.event_table = OML.table2.extend({
    decl_properties: [
    ],
    
    defaults: function() {
      return this.deep_defaults({
      }, OML.event_table.__super__.defaults.call(this));      
    },    
    
    base_css_class: 'oml-event-table',
    
    init_grid: function() {
      OML.event_table.__super__.init_grid.call(this);

      var grid = this.grid;
      var self = this;
      
      grid.setSelectionModel(new Slick.RowSelectionModel());
      grid.onSelectedRowsChanged.subscribe(function(e, args) {
        var rindex = args.rows[0];
        var row = self.data[rindex];
        var event_id = row[self.schema.eventID.index];
        if (event_id) {
          OHUB.trigger("bridge.event_selected", {event: row, schema: self.schema});
        }
      });
    },
    
    init_columns: function() {
      var columns = OML.event_table.__super__.init_columns.call(this);
      
      // var checkboxSelector = new Slick.CheckboxSelectColumn({
        // cssClass: "slick-cell-checkboxsel"
      // });
      // columns.splice(0, 0, checkboxSelector.getColumnDefinition());
      return columns;
    },

    
  }) // end of event-table
}) // end of provide
