var http = require('./http');
var prototype = require('prote');

var documentPrototype = require('./document');
function createDocumentFromResponse(response) {
  return documentPrototype(response.body);
}

module.exports = prototype({
  currentDocument: function () {
    var self = this;

    return http.get('/api/user/documents/current', {suppressErrors: true}).then(createDocumentFromResponse, function (error) {
    });
  },

  document: function (id, options) {
    if (id instanceof Object) {
      return documentPrototype(id);
    } else {
      return http.get('/api/user/documents/' + id, options).then(createDocumentFromResponse);
    }
  },

  create: function () {
    return http.post('/api/user/documents', {lexemes: []}).then(createDocumentFromResponse);
  },

  delete: function (id) {
    return http.delete('/api/user/documents/' + id);
  },

  allDocuments: function () {
    return http.get('/api/user/documents').then(function (response) {
      return response.body.map(documentPrototype);
    });
  }
});

