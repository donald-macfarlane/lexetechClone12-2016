var React = require('react')
var r = React.createElement;

module.exports = function (obj) {
  return r('pre', {}, r('code', {}, JSON.stringify(obj, null, 2)));
};
