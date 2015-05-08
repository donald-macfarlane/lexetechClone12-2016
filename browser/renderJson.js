var h = require('plastiq').html;

module.exports = function (obj) {
  return h('pre code', JSON.stringify(obj, null, 2));
};
