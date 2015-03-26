var plastiq = require('plastiq');
var h = plastiq.html;
var reportComponent = require('./report');
var prototype = require('prote');
var login = require('./login');
var signup = require('./signup');
var layout = require('./layout');
var documentsApi = require('./documentsApi')();
var router = require('./router');

var rootComponent = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;
    this.graphHack = pageData.graphHack;
    this.documentsApi = documentsApi;
  },

  openDocumentById: function (docId) {
    var self = this;

    return this.documentsApi.document(self.documentId).then(function (doc) {
      self.openDocument(doc);
    });
  },

  openDocument: function (doc) {
    this.document = doc;
    this.documentId = doc.id;
    this.report = reportComponent({user: this.user, document: doc, graphHack: this.graphHack});
  },

  createDocument: function () {
    var self = this;

    return this.documentsApi.create().then(function (doc) {
      self.openDocument(doc);
    });
  },

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    function master(fn) {
      return function() {
        return layout(self, fn.apply(this, arguments));
      };
    }

    return router.render(this, function () {
      return layout(self,
        self.login ?
          router.login(login())
          : self.signup ?
            router.signup(signup())
            : self.documentId ?
              router.report({documentId: self.documentId}, self.document,
                self.report
                  ? self.report.render()
                  : h('h1', 'loading')
              )
              : h('.app',
                  h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Start new document'),
                  h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Load previous document')
                )
      );
    });
  }
});

module.exports = rootComponent;
