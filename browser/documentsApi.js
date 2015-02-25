var http = require('./http');
var prototype = require('prote');

module.exports = prototype({
  currentDocument: function () {
    if (!this.document) {
      var self = this;
      console.log('checking if there is a last');
      return http.get('/api/user/documents/last').then(undefined, function (error) {
        console.log('no document found, creating new document', error);
        return http.post('/api/user/documents', {});
      }).then(function (doc) {
        console.log('got document', doc);
        self.document = doc;
        return doc;
      });
    } else {
      console.log('already have document');
      return Promise.resolve(this.document);
    }
  },

  updateDocument: function (doc) {
    console.log('updating document');
    return this.currentDocument().then(function (originalDoc) {
      console.log('updating document', originalDoc.href, doc);
      return http.post(originalDoc.href, doc);
    });
  }
});

