var http = require('./http');
var prototype = require('prote');

module.exports = prototype({
  currentDocument: function () {
    if (!this.document) {
      var self = this;

      if (!this.last) {
        this.last = http.get('/api/user/documents/last').then(undefined, function (error) {
          return http.post('/api/user/documents', {});
        }).then(function (doc) {
          self.document = doc;
          return doc;
        });
      }

      return this.last;
    } else {
      return Promise.resolve(this.document);
    }
  },

  updateDocument: function (doc) {
    return this.currentDocument().then(function (originalDoc) {
      return http.post(originalDoc.href, doc);
    });
  }
});

