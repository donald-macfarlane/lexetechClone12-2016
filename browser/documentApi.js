var http = require('./http');
var prototype = require('prote');

var documentPrototype = require('./document');

module.exports = prototype({
  currentDocument: function () {
    var self = this;

    return http.get('/api/user/documents/current', {suppressErrors: true}).then(documentPrototype, function (error) {
    });
  },

  document: function (id, options) {
    if (id instanceof Object) {
      return documentPrototype(id);
    } else {
      return http.get('/api/user/documents/' + id, options).then(documentPrototype);
    }
  },

  create: function () {
    return http.post('/api/user/documents', {lexemes: []}).then(documentPrototype);
  },

  delete: function (id) {
    return http.delete('/api/user/documents/' + id);
  },

  allDocuments: function () {
    return http.get('/api/user/documents').then(function (docs) {
      return docs.map(documentPrototype);
    });
  }
});

