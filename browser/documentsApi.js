var http = require('./http');
var prototype = require('prote');
var _ = require('underscore');

var documentPrototype = prototype({
  update: function (doc) {
    _.extend(this, doc);
    return http.post(this.href, this);
  }
});

module.exports = prototype({
  currentDocument: function () {
    var self = this;

    return http.get('/api/user/documents/current').then(undefined, function (error) {
      return self.create();
    });
  },

  document: function (id) {
    if (id instanceof Object) {
      return documentPrototype(id);
    } else {
      return http.get('/api/user/documents/' + id).then(documentPrototype);
    }
  },

  create: function () {
    return http.post('/api/user/documents', {lexemes: []}).then(documentPrototype);
  }
});

