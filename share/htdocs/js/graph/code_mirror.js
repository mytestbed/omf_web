L.provide('OML.code_mirror', 
    [
      "graph/abstract_widget", "#OML.abstract_widget"
    ], 
    function () {

  OML.code_mirror = OML.abstract_widget.extend({
    
    defaults: function() {
      return this.deep_defaults({
        height: 1.0,
        margin: {
          left: 20,
          top:  10,
          right: 20,
          bottom: 10
        },
      }, OML.code_mirror.__super__.defaults.call(this));      
    },    
    
    
    initialize: function(opts) {
      OML.code_mirror.__super__.initialize.call(this, opts);
      this.update();
    },
    
    update: function() {
      var o = this.opts;
      
      if ($(o.base_el).is(':hidden')) {
        return;
      }

      // TODO: When we create a code mirror object and then make the 
      // encompassing element invisible and visible again, things seem 
      // go astray. Brute force solution is to recreate the editor on every 
      // update.
      
      //if (!o.code_mirror) {
        var edit_el = $(o.edit_el);
        edit_el.empty(); // remove old instances if any
        
        CodeMirror.modeURL = "/resource/vendor/codemirror/mode/%N/%N.js";

        var self = this;
        var cm_o = {
          value: o.content,
          mode: o.mode,
          lineNumbers: true,
          matchBrackets: true,
          tabMode: "indent",
          onCursorActivity: function() {
            // try to highlight active line
            cm.setLineClass(hlLine, null, null);
            hlLine = cm.setLineClass(cm.getCursor().line, null, "activeline");
          },
          onChange: function(editor, changed) {
            self.on_changed(editor, changed);
          }
        };
        var cm = this.code_mirror = CodeMirror(edit_el[0], cm_o);
        CodeMirror.autoLoadMode(cm, o.mode);

        var hlLine = cm.setLineClass(0, "activeline");
        
        var s_el = $(o.base_el + " .CodeMirror-scroll");
        s_el.css('height', this.h);
      //}
      this.on_changed(this.code_mirror, null);
      this.code_mirror.refresh();
      this.code_mirror.focus();
    },
    
    on_changed: function(editor, change) {
      if (editor == undefined) return;
      
      var o = this.opts;
      var h = editor.historySize();

      var save = h.undo > 0;
      var undo = h.undo > 0;
      var redo = h.redo > 0;
      $(o.base_el + '_save_a').fadeTo('fast', save ? 1.0 : 0.3);
      $(o.base_el + '_undo_a').fadeTo('fast', undo ? 1.0 : 0.3);
      $(o.base_el + '_redo_a').fadeTo('fast', redo ? 1.0 : 0.3);            
    },
    
    on_save_pressed: function() {
      var o = this.opts;
      var self = this;
      var cm = this.code_mirror;
      
      $.ajax({
        url: o.save_url,
        data: {content: cm.getValue()},
        type: 'POST'
      }).done(function() { 
        cm.clearHistory();
        self.on_changed(cm, null);
        OHUB.trigger('content.changed.' + o.content_id, {});
      });
    },
    
    on_undo_pressed: function() {
      this.code_mirror.undo();
    },
    
    on_redo_pressed: function() {
      this.code_mirror.redo();
    },

    resize: function() {
      OML.code_mirror.__super__.resize.call(this);
      var i = 0;      
    },
    
    init_data_source: function() {},
    process_schema: function() {},
        
  }) /* end of OML.code_mirror */
  
}) /* end of L.provide */