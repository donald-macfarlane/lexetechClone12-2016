var plastiq = require('plastiq');
var h = plastiq.html;
var reportComponent = require('./report');
var prototype = require('prote');
var login = require('./login');
var signup = require('./signup');
var layout = require('./layout');
var documentsApi = require('./documentsApi')();
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
      this.documentsApi = documentsApi;

      this.startReport = startReportComponent({
        documentsApi: documentsApi,
        root: {openDocument: this.openDocument.bind(this)},
        user: this.user
      });
    }
  },

  openDocumentById: function (docId) {
    var self = this;

    return this.documentsApi.document(docId).then(function (doc) {
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

    function master(fn) {
      return function() {
        return layout(self, fn.apply(this, arguments));
      };
    }

    return router.render(this, function () {
      return layout(self,
        self.signup ?
          router.signup(signup())
        : self.login || !self.user ?
          router.login(login())
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
