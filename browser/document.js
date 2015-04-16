var _ = require('underscore');
var http = require('./http');
var prototype = require('prote');

module.exports = prototype({
  update: function (doc) {
    _.extend(this, doc);
    return http.post(this.href, this);
  }
});
