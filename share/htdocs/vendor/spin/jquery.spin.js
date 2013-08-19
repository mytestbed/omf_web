
// Copied from http://fgnass.github.io/spin.js

  // var opts = {
    // lines: 13, // The number of lines to draw
    // length: 20, // The length of each line
    // width: 10, // The line thickness
    // radius: 30, // The radius of the inner circle
    // corners: 1, // Corner roundness (0..1)
    // rotate: 0, // The rotation offset
    // direction: 1, // 1: clockwise, -1: counterclockwise
    // color: '#000', // #rgb or #rrggbb
    // speed: 1, // Rounds per second
    // trail: 60, // Afterglow percentage
    // shadow: false, // Whether to render a shadow
    // hwaccel: false, // Whether to use hardware acceleration
    // className: 'spinner', // The CSS class to assign to the spinner
    // zIndex: 2e9, // The z-index (defaults to 2000000000)
    // top: 'auto', // Top position relative to parent in px
    // left: 'auto' // Left position relative to parent in px
  // };

function _jquery_spin_() {
  $.fn.spin = function(opts) {
    this.each(function() {
      var $this = $(this),
          data = $this.data();

      if (data.spinner) {
        data.spinner.stop();
        delete data.spinner;
      }
      if (opts !== false) {
        data.spinner = new Spinner($.extend({left: '0px', color: $this.css('color')}, opts)).spin(this);
      }
    });
    return this;
  };
}

if (L != undefined) {
  L.provide('jquery.spin', ['/resource/vendor/spin/spin.min.js'], _jquery_spin_);
} else {
  // This assumes that /resource/vendor/spin/spin.min.js has already been loaded
  _jquery_spin_();
}
