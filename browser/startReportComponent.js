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

  newDocumentButton: function() {
    var self = this;
    return h('.ui.button.new-document', {onclick: self.createDocument.bind(self)}, 'Start new document');
  },

  documentList: function() {
    var self = this;
    return [
      h('div.your-documents',
        self.newDocumentButton(),
        h('h1', 'Your documents'),
        h('table.table.ui.celled.menu.documents',
          h('thead',
            h('tr',
              h('th', 'Name'),
              h('th', 'Created'),
              h('th', 'Modified')
            )
          ),
          h('tbody',
            self.documents.map(function (doc) {
              return h('tr.button.document.load-document', {onclick: function() {return self.loadDocument(doc.id)}},
                h('td.name', doc.name || 'Untitled2'),
                h('td',moment(doc.created).format('LLL')),
                h('td',moment(doc.lastModified).format('LLL'))
              )
            })
          )
        )
      )
    ];
  },

  getStarted: function() {
    var self = this;
    return h('div.no-documents',
      h('h1', 'Your documents'),
      h('p', 'You have not yet created any documents.'),
      h('p', 
        h('a', {href: '#tutorial'}, 'Read the tutorial'),
        ' or start a new document when you are ready:'
      ),
      self.newDocumentButton()
    );
  },

  render: function () {
    var self = this;
    this.refresh = h.refresh;

    var currentDocument = this.currentDocument();

    return h('.documents',
      self.documents && false ? self.documentList() : self.getStarted() 
    )
  }
});
