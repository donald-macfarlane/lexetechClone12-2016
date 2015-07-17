var plastiq = require('plastiq');
var h = plastiq.html;
var prototype = require('prote');
var semanticUi = require('plastiq-semantic-ui');
var moment = require('moment');
var throttle = require('plastiq-throttle');
var debug = require('debug')('start-report');

module.exports = prototype({
  constructor: function (options) {
    this.user = options.user;
    this.documentApi = options.documentApi;
    this.root = options.root;
    this.currentDocument = options.currentDocument;
  },

  refresh: function () {},

  loadDocuments: function() {
    var self = this;
    if (self.user) {
      return self.documentApi.allDocuments().then(function (documents) {
        self.documents = documents;
      });
    }
  },

  createDocument: function () {
    var self = this;

    return this.documentApi.create().then(function (doc) {
      self.root.openDocument(doc);
    });
  },

  loadCurrentDocument: function () {
    var self = this;

    return self.documentApi.currentDocument().then(function (doc) {
      self.root.openDocument(doc);
    });
  },

  loadDocument: function (id) {
    var self = this;

    return this.documentApi.document(id).then(function (doc) {
      self.root.openDocument(doc);
    });
  },


  render: function () {
    var self = this;
    this.refresh = h.refresh;

    var currentDocument = this.currentDocument();

    return h('.documents',
      h('.ui.basic.button', {onclick: self.createDocument.bind(self)}, 'Start new document'),
      h('h1', 'Your reports'),
      h('table.table.ui.celled.menu.documents',
        h('thead',
          h('tr',
            h('th', 'Name'),
            h('th', 'Created'),
            h('th', 'Modified')
          )
        ),
        h('tbody',
          self.documents? self.documents.map(function (doc) {
            return h('tr.button.load-document', {onclick: function() {return self.loadDocument(doc.id)}},
              h('td.name', doc.name || 'Untitled2'),
              h('td',moment(doc.created).format('LLL')),
              h('td',moment(doc.lastModified).format('LLL'))
            )
          }): undefined
        )
      )
    )
  }
});
