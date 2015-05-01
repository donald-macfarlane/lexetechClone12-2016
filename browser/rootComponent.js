var plastiq = require('plastiq');
var h = plastiq.html;
var reportComponent = require('./reportComponent');
var prototype = require('prote');
var loginComponent = require('./loginComponent');
var signupComponent = require('./signupComponent');
var layoutComponent = require('./layoutComponent');
var documentApi = require('./documentApi')();
var routes = require('./routes');
var buildGraph = require('./buildGraph');
var lexemeApi = require('./lexemeApi');
var startReportComponent = require('./startReportComponent');
var sync = require('./sync');
var adminComponent = require('./adminComponent');

var rootComponent = prototype({
  constructor: function (pageData) {
    this.user = pageData.user;
    this.flash = pageData.flash;

    if (pageData.user) {
      this.graphHack = pageData.graphHack;
      this.documentApi = documentApi;
      this.admin = adminComponent();

      this.startReport = startReportComponent({
        documentApi: documentApi,
        root: {openDocument: this.openDocument.bind(this)},
        user: this.user,
        currentDocument: this.currentDocument.bind(this)
      });
    }
  },

  openDocumentById: function (docId) {
    var self = this;

    if (docId != this.documentId) {
      return this.documentApi.document(docId).then(function (doc) {
        self.openDocument(doc);
      });
    }
  },

  query: function () {
    return this.report && this.report.history.query;
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
    this.setCurrentDocument(doc);
    this.documentId = doc.id;
    this.report = reportComponent({
      user: this.user,
      document: doc,
      queryGraph: this.queryGraph(),
      lexemeApi: this.lexemeApi()
    });
    routes.report({documentId: doc.id}).push();
  },

  currentDocument: function () {
    var self = this;

    if (!this.syncHasCurrentDocument) {
      this.syncHasCurrentDocument = sync({
        throttle: 5000,
        condition: function () { return self.user && !self._currentDocument; }
      }, function () {
        return self.documentApi.currentDocument().then(function (doc) {
          if (!self._currentDocument) {
            self.setCurrentDocument(doc);
          }

          return doc? undefined: h.norefresh;
        });
      });
    }

    this.syncHasCurrentDocument();

    return self._currentDocument;
  },

  setCurrentDocument: function (doc) {
    this._currentDocument = doc;
  },

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    if (!self.user && (!routes.signup().active && !routes.login().active)) {
      routes.login().push();
    }

    return layoutComponent(self, [
      routes.signup(signupComponent),
      routes.login(loginComponent),
      routes.report(
        {
          documentId: {
            set: function (docId) {
              return self.openDocumentById(docId);
            }
          },
        },
        function (params) {
          if (self.report) {
            return self.report.render();
          } else {
            return h('h1', 'loading');
          }
        }
      ),
      routes.root(function () {
        return self.startReport.render();
      }),
      routes.admin(function () {
        return self.admin.render();
      }),
      routes.adminUser(function (params) {
        return self.admin.render(params.userId);
      })
    ]);
  }
});

module.exports = rootComponent;
