define(['omf/data_source_repo', 'vendor/d3/d3'], function(ds_repo) {

  if (typeof(d3.each) == 'undefined') {
    d3.each = function(array, f) {
      var i = 0, n = array.length, a = array[0], b;
      if (arguments.length == 1) {
          while (++i < n) if (a < (b = array[i])) a = b;
      } else {
        a = f(a);
        while (++i < n) if (a < (b = f(array[i]))) a = b;
      }
      return a;
    };
  };


  var abstract_widget = Backbone.Model.extend({

    defaults: function() {
      return {
        base_el: "body",
        width: 1.0,  // <= 1.0 means set width to enclosing element
        height: 0.6,  // <= 1.0 means fraction of width
        margin: {
          left: 20,
          top:  20,
          right: 20,
          bottom: 20
        },
        offset: {
          x: 0,
          y: 0
        },
      };
    },

    //base_css_class: 'oml-chart',

    initialize: function(opts) {
      var o = this.opts = this.deep_defaults(opts, this.defaults());

      var base_el = o.base_el;
      if (typeof(base_el) == "string") base_el = d3.select(base_el);
      this.base_el = base_el;

      this.init_data_source();
      this.process_schema();
      this.resize();

      var self = this;
      OHUB.bind('layout.resize', function(e) {
        self.resize();
        self.update();
      });
    },

    update: function() {
      if ($(this.opts.base_el).is(':hidden')) {
        return;
      }

      var data;
      if ((data = this.data_source.rows()) == null) {
        throw "Missing rows in data source"
      }
      if (data.length == 0) return;

      this.redraw(data);

    },

    resize: function() {
      var o = this.opts;
      var w = o.width;
      if (w <= 1.0) {
        // check width of enclosing div (base_el)
        var bel = $(o.base_el).parents(".widget_container");
        var el = bel[0];
        bel.resize(function(_) {  // doesn't seem to work
          var i = 0;
          i + 1;
          alert(i);
        });
        var elw = bel.width();
        w = w * elw;
        //w = w * this.base_el[0][0].clientWidth;
        if (isNaN(w)) w = 800;
      }

      var h = o.height;
      if (h <= 1.0) {
        h = h * w;
      }
      this._resize_base_el(w,h);

      OHUB.trigger(o.id + '.resize', {width: w, height: h});

      return this;
    },


    _resize_base_el: function(w, h) {
      var m = this.opts.margin;
      this.w = w - m.left - m.right; // take away the margins
      this.h = h - m.top - m.bottom;
      this.base_el
        .style('height', this.h + 'px')
        .style('width', this.w + 'px')
        .style('margin-left', m.left + 'px')
        .style('margin-right', m.right + 'px')
        .style('margin-top', m.top + 'px')
        .style('margin-bottom', m.bottom + 'px')
        ;
    },


    // Find the appropriate data source and bind to it
    //
    init_data_source: function() {
      var o = this.opts;
      var sources = o.data_sources;
      var self = this;

      if (! (sources instanceof Array)) {
        throw "Expected an array";
      }
      if (sources.length != 1) {
        throw "Can only process a SINGLE source";
      }
      this.data_source = this.init_single_data_source(sources[0]);
    },


    // Find the appropriate data source and bind to it
    //
    init_single_data_source: function(ds_descr) {
      var ds = ds_repo.lookup(ds_descr);
      var self = this;
      OHUB.bind(ds.event_name, function() {
        self.update();;
      });
      return ds;
    },

    init_mapping: function() {},

    process_schema: function() {
      var self = this;
      this.data_source.on_schema(function() {
        self.schema = self.process_single_schema(self.data_source);
        if (typeof(self.decl_properties) != "undefined") {
          self.mapping = self.process_single_mapping(null, self.opts.mapping, self.decl_properties);
        }
        self.init_mapping();
      });
    },

    process_single_schema: function(data_source) {
      var self = this;
      var o = this.opts;
      var schema = {};
      _.map(data_source.schema, function(s, i) {
        // TODO: Remove, this is quick hack to addres a bug in Job Service
        if (_.isArray(s)) { s = {name: s[0], type: s[1]}; }
        // End of hack

        s['index'] = i;
        schema[s.name] = s;
      });
      return schema;
    },

    process_single_mapping: function(source_name, mapping_decl, properties_decl) {
      var self = this;
      var m = {};
      var om = mapping_decl || {};
      _.map(properties_decl, function(a) {
        var pname = a[0]; var type = a[1]; var def = a[2];
        var descr = om[pname];
        m[pname] = self.create_mapping(pname, descr, source_name, type, def);
      });
      return m;
    },

    /*
     * Return schema for +stream+.
     */
    schema_for_stream: function(stream) {
      if (stream != undefined) {
        throw "Can't provide named stream '" + stream + "'.";
      }
      return this.schema;
    },

    /*
     * Return data_source named 'name'.
     */
    data_source_for_stream: function(name) {
      if (name != undefined) {
        throw "Can't provide named stream '" + name + "'.";
      }
      return this.data_source;
    },

    create_mapping: function(mname, descr, stream, type, def) {
       var self = this;
       if (descr == undefined && typeof(def) == 'object') {
         descr = def;
       }
       if (descr == undefined || typeof(descr) != 'object' ) {
         if (type == 'index') {
           return this.create_mapping(mname, def, stream, type, null);
         } else if (type == 'key') {
           return this.create_mapping(mname, {property: descr}, stream, type, def);
         } else {
           var value = (descr == undefined) ? def : descr;
           if (type == 'color' && /\(\)$/.test(value)) { // check if value ends with () indicating color function
             var cf = this.decl_color_func[value];
             var cf_i = cf();
             value = function(x) {
               return cf_i(x);
             };
           }
           return value;
         }
       }
       if (descr.stream != undefined) {
         stream = descr.stream;  // override stream
       }
       var schema = this.schema_for_stream(stream);
       if (schema == undefined) {
         throw "Can't find schema for stream '" + stream + "'.";
       }

       if (type == 'index') {
         var key = descr.key;
         if (key == undefined || stream == undefined) {
           throw "Missing 'key' or 'stream' in mapping declaration for '" + mname + "'.";
         }
         var col_schema = schema[key];
         if (col_schema == undefined) {
           throw "Unknown stream element '" + key + "'.";
         }
         var vindex = col_schema.index;

         var jstream_name = descr.join_stream;
         if (jstream_name == undefined) {
           throw "Missing join stream declaration in '" + mname + "'.";
         }
         var jschema = this.schema_for_stream(jstream_name);
         if (jschema == undefined) {
           throw "Can't find schema for stream '" + jstream_name + "'.";
         }
         var jstream = this.data_source_for_stream(jstream_name);

         var jkey = descr.join_key;
         if (jkey == undefined) jkey = 'id';
         var jcol_schema = jschema[jkey];
         if (jcol_schema == undefined) {
           throw "Unknown stream element '" + jkey + "' in '" + jstream + "'.";
         }
         var index_f = jstream.index_for_column(jcol_schema);

         return function(d) {
           var join = d[vindex];
           //var t = jstream.get_indexed_row(jindex, join); //self.get_indexed_table(jstream, jindex);
           var t = index_f(join);
           //var r = t[join];
           return t;
         };
       } else {
         if (descr.values) {
           // provided custom mapping for values
           var values = descr.values;
           var def_value = descr['default'];
           return function(x) {
             return values[x] || def_value;
           };
         }
         var pname = descr.property;
         if (pname == undefined) {
           throw "Missing 'property' declaration for mapping '" + mname + "'.";
         }
         var col_schema = schema[pname];
         if (col_schema == undefined) {
           if (descr.optional == true) {
             return undefined;  // don't need to be mapped
           }
           throw "Unknown property '" + pname + "'.";
         }
         var index = col_schema.index;
         switch (type) {
         case 'int':
         case 'float':
         case 'key' :
           var scale = descr.scale;
           var min_value = descr.min;
           var max_value = descr.max;
           return function(d) {
             var v = d[index];
             if (scale != undefined) v = v * scale;
             if (min_value != undefined && v < min_value) v = min_value;
             if (max_value != undefined && v > max_value) v = max_value;
             return v;
           };
         case 'color':
           var color_fdecl = descr.color;
           if (color_fdecl == undefined) {
             throw "Missing color mapping declaration for '" + mname + "'.";
           }
           var color_f = null;
           if (typeof color_fdecl == 'string') {
             var color_fp = self.decl_color_func[color_fdecl];
             if (color_fp == undefined) {
               throw "Unknown color function '" + color_fname + "'.";
             }
             color_f = color_fp();
           } else if (color_fdecl instanceof Object) {
             if (color_fdecl instanceof Array) {
               var l = color_fdecl.length;
               color_f = function(v) {
                 if (v < 0) v = 0;
                 if (v >= l) v = l - 1;
                 return color_fdecl[v];
               };
             } else {
               // hash table, mapping some name to color
               return function(d) {
                 var key = d[index];
                 var c = color_fdecl[key] || 'black';
                 return c;
               };
             }
           } else {
             throw "Unknown color function type '" + color_fdecl + "'.";
           }
           var scale = descr.scale;
           var min_value = descr.min;
           return function(d) {
             var v = parseInt(d[index]);
             if (scale != undefined) v = v * scale;
             if (min_value != undefined && v < min_value) v = min_value;
             var color = color_f(v);
             return color;
           };
         // case 'key' :
           // return function(d) {
             // return d[index];
           // }
         default:
           throw "Unknown mapping type '" + type + "'";
         }
       }
       var i = 0;
    },


    // Fill in a given object (and any objects it contains) with default properties.
    // ... borrowed from unerscore.js
    //
    deep_defaults: function(source, defaults) {
      for (var prop in defaults) {
        if (source[prop] == null) {
          source[prop] = defaults[prop];
        } else if((typeof(source[prop]) == 'object') && defaults[prop]) {
          this.deep_defaults(source[prop], defaults[prop]);
        }
      }
      return source;
    },


  });

  return abstract_widget;
});
