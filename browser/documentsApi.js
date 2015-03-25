var http = require('./http');
var prototype = require('prote');

var documentPrototype = prototype({
  update: function (doc) {
    return http.post(this.href, doc);
  }
});

module.exports = prototype({
  currentDocument: function () {
    return http.get('/api/user/documents/current').then(undefined, function (error) {
      return http.post('/api/user/documents', {});
    }).then(documentPrototype);
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

