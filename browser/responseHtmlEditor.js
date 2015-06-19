var ckeditor = require('plastiq-ckeditor');

var ckeditorConfig = require('./ckeditorConfig');

module.exports = function(options) {
  return ckeditor({
    class: options.class,
    binding: options.binding,
    inline: true,
    config: ckeditorConfig
  });
};
