var React = require('react');
var r = React.createElement;
var ckeditor = require('./reactCkeditor');
var ckeditorConfig = require('../../ckeditorConfig');

module.exports = React.createClass({
  render: function () {
    return r(ckeditor, extend({inline: true, config: ckeditorConfig}, this.props));
  }
});

function extend(object, extension) {
  Object.keys(extension).forEach(function (key) {
    object[key] = extension[key];
  });

  return object;
}
