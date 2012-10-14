L.provide('OML.mustache', ["vendor/mustache/mustache.js", 'vendor/bootstrap/css/bootstrap.css'], function () {

  if (typeof(OML) == "undefined") OML = {};

  OML['mustache'] = function(opts) {
    
    var moustache = {
      version: "0.1",
    }
    
    var template_url = opts.template;
    if (! template_url) {
      throw "Missing template declaration in mustache widget";
    }
    var context = {};
    var el = $('#' + opts.base_id);
    
    $.ajax({
      url: '/resource/' + template_url,
      type: 'get'
    }).done(function(template) {
      var html = Mustache.to_html(template, context);
      el.html(html);
      var i = 0;
    }) 

    return moustache;
  }
})