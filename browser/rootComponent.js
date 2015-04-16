var plastiq = require('plastiq');
var h = plastiq.html;
var reportComponent = require('./reportComponent');
var prototype = require('prote');
var loginComponent = require('./loginComponent');
var signupComponent = require('./signupComponent');
var layoutComponent = require('./layoutComponent');
var documentApi = require('./documentApi')();
var router = require('./router');
var buildGraph = require('./buildGraph');
var lexemeApi = require('./lexemeApi');
var startReportComponent = require('./startReportComponent');

var rootComponent = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;

    if (pageData.user) {
      this.graphHack = pageData.graphHack;
      this.documentApi = documentApi;

      this.startReport = startReportComponent({
        documentApi: documentApi,
        root: {openDocument: this.openDocument.bind(this)},
        user: this.user
      });
    }
  },

  openDocumentById: function (docId) {
    var self = this;

    return this.documentApi.document(docId).then(function (doc) {
      self.openDocument(doc);
    });
  },

  lexemeApi: function () {
    return this._lexemeApi || (
      this._lexemeApi = lexemeApi()
    );
  },

  queryGraph: function () {
    return this._queryGraph || (
      this._queryGraph = buildGraph({
        hack: this.graphHack !== undefined? this.graphHack: true,
        lexemeApi: this.lexemeApi()
      })
    );
  },

  openDocument: function (doc) {
    this.document = doc;
    this.documentId = doc.id;
    this.report = reportComponent({
      user: this.user,
      document: doc,
      queryGraph: this.queryGraph(),
      lexemeApi: this.lexemeApi()
    });
  },


  render: function () {
    var self = this;
    this.refresh = h.refresh;

    return router.render(this, function () {
      return layoutComponent(self,
        self.signup ?
          router.signup(signupComponent())
        : self.login || !self.user ?
          router.login(loginComponent())
        : self.documentId ?
          router.report({documentId: self.documentId}, self.document,
            self.report
              ? self.report.render()
              : h('h1', 'loading')
          )
        : router.root(self.startReport.render())
      );
    });
  }
});

module.exports = rootComponent;
