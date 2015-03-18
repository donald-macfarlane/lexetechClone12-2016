var plastiq = require('plastiq');
var h = plastiq.html;
require('./jquery');
require('../../semantic/dist/components/tab');

module.exports = function tab(vdom) {
  return h.component(
    {
      onadd: function (element) {
        $(element).find('.item').tab();
      }
    },
    vdom
  );
};
