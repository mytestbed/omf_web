L.provide('OML.mustache', ["vendor/mustache/mustache.js", 'vendor/bootstrap/css/bootstrap.css'], function () {

  if (typeof(OML) == "undefined") OML = {};

  OML['mustache'] = function(opts) {
    
    var moustache = {
      version: "0.1",
    }
    
    var context = opts.context || {};
    var el = $('#' + opts.base_id);
    var render_f = function(template) {
      var html = Mustache.to_html(template, context);
      el.html(html);
      var i = 0;
    };
    
    var text = opts.text;
    if (text) { //} != undefined) {
      render_f(text);
    } else {
      var template_url = opts.template;
      if (! template_url) {
        throw "Missing template declaration in mustache widget";
      }
      $.ajax({
        url: '/resource/' + template_url,
        type: 'get'
      }).done(render_f);
    }

    return moustache;
  }
})