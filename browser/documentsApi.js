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

    return http.get('/api/user/documents/current').then(documentPrototype, function (error) {
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
  },

  allDocuments: function () {
    return http.get('/api/user/documents').then(function (docs) {
      return docs.map(documentPrototype);
    });
  }
});

