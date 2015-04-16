var createQueryApi = require('./queryApi');
var createDocumentApi = require('../../browser/documentApi');
var expect = require('chai').expect;
var createHistory = require('../../browser/history');
var retry = require('trytryagain');
var buildGraph = require('../../browser/buildGraph');
var simpleLexicon = require('../simpleLexicon');
var loopingLexicon = require('../loopingLexicon');
var Promise = require('bluebird');

describe('history', function () {
  var documentApi;
  var queryGraph;
  var query;
  var lexicon;
  var history;

  beforeEach(function () {
    documentApi = createDocumentApi();
    server = createQueryApi();
    queryGraph = buildGraph({cache: true});
  });

  itCanRunLexicon({saving: true});
  itCanRunLexicon({saving: false});

  function itCanRunLexicon(options) {
    var only = options && options.hasOwnProperty('only') && options.only !== undefined
      ? function (x) { return x.only }
      : function (x) { return x; };

    describe('can run lexicon' + (options.saving? ' (saving)': ''), function () {
      var savedDocument;

      function historyWithDocument(document) {
        savedDocument = document;
        history = createHistory({
          queryGraph: queryGraph,
          document: document,
          setQuery: function (q) {
            query = q;
          }
        });
      }

      function selectResponse(text) {
        var response = query.responses.filter(function (f) { return f.text == text; })[0];
        var errorMessage = 'expected response to be one of ' + query.responses.map(function (r) { return r.text; }).join(', ');

        expect(response, errorMessage).to.exist;

        return reloadHistory(history.selectResponse(response));
      }

      function reloadHistory(result) {
        var queryPromise = Promise.all([
          result.query,
          result.documentSaved
        ]).then(function (results) {
          query = results[0];
        });

        if (options.saving) {
          return queryPromise.then(function () {
            return documentApi.document(savedDocument.id);
          }).then(function (doc) {
            expect(server.documents.length, 'expected one document').to.equal(1);
            historyWithDocument(doc);
          }).then(function () {
            return currentQuery();
          });
        } else {
          return queryPromise;
        }
      }

      function currentQuery() {
        return Promise.resolve(history.currentQuery()).then(function (q) {
          query = q;
        });
      }

      function expectQuery(text) {
        expect(query.query.text).to.equal(text);
      }

      function expectFinished() {
        expect(query.query, 'expected to be finished').to.not.exist;
      }

      function selectResponseAndExpectQuery(responseText, queryText) {
        return selectResponse(responseText).then(function () {
          expectQuery(queryText);
        });
      }

      function undo() {
        return reloadHistory(history.undo());
      }

      function accept() {
        return reloadHistory(history.accept());
      }

      context('with a new document', function () {
        beforeEach(function () {
          lexicon = simpleLexicon();
          server.setLexicon(lexicon);
          return documentApi.create().then(function (doc) {
            expect(server.documents.length, 'expected one document').to.equal(1);
            historyWithDocument(doc);
          });
        });

        it('saves history', function () {
          return currentQuery().then(function (firstQuery) {
            return selectResponseAndExpectQuery('left leg', 'Is it bleeding?');
          }).then(function (query) {
            expect(server.documents.length).to.equal(1);
            var doc = server.documents[0];
            expect(doc.lexemes.length).to.equal(1);
            return doc;
          }).then(function (doc) {
            var lexeme = doc.lexemes[0];

            expect(lexeme.query.id).to.equal(lexicon.blocks[0].queries[0].id);
            expect(lexeme.query.name).to.equal(lexicon.blocks[0].queries[0].name);

            expect(lexeme.response.id).to.equal(lexicon.blocks[0].queries[0].responses[0].id);
            expect(lexeme.response.text).to.equal(lexicon.blocks[0].queries[0].responses[0].text);
            expect(lexeme.response.repeat).to.equal(false);
            expect(lexeme.response.styles.style1).to.equal(lexicon.blocks[0].queries[0].responses[0].styles.style1);
          });
        });

        it('can undo and accept', function () {
          return currentQuery().then(function () {
            expectQuery('Where does it hurt?');
            return selectResponseAndExpectQuery('left leg', 'Is it bleeding?');
          }).then(function () {
            return selectResponseAndExpectQuery('yes', 'Is it aching?');
          }).then(function () {
            return undo();
          }).then(function () {
            expectQuery('Is it bleeding?');
            return undo();
          }).then(function () {
            expectQuery('Where does it hurt?');
            return accept();
          }).then(function () {
            expectQuery('Is it bleeding?');
            return accept();
          }).then(function () {
            expectQuery('Is it aching?');
          });
        });
      });

      describe('looping', function () {
        beforeEach(function () {
          lexicon = loopingLexicon();
          server.setLexicon(lexicon);
          return documentApi.create().then(function (doc) {
            expect(server.documents.length, 'expected one document').to.equal(1);
            historyWithDocument(doc);
          });
        });

        it('can loop', function () {
          return currentQuery().then(function () {
            expectQuery('query 1, level 1');
          }).then(function () {
            return selectResponseAndExpectQuery('response 1', 'query 2, level 2');
          }).then(function (result) {
            return selectResponseAndExpectQuery('response 1 (left)', 'query 3, level 2 (left)');
          }).then(function () {
            return selectResponseAndExpectQuery('response 1', 'query 5, level 2');
          }).then(function () {
            return selectResponseAndExpectQuery('again', 'query 1, level 1');
          }).then(function () {
            return selectResponseAndExpectQuery('response 1', 'query 2, level 2');
          }).then(function () {
            return selectResponseAndExpectQuery('response 2 (right)', 'query 4, level 2 (right)');
          }).then(function () {
            return selectResponseAndExpectQuery('response 1', 'query 5, level 2');
          }).then(function () {
            return selectResponseAndExpectQuery('no more', 'query 6, level 1');
          }).then(function () {
            return selectResponseAndExpectQuery('response 1', 'query 7, level 1 (left)');
          }).then(function () {
            return selectResponseAndExpectQuery('response 1', 'query 8, level 1 (right)');
          }).then(function () {
            return selectResponse('response 1');
          }).then(function () {
            expectFinished();
          });
        });
      });
    });
  }
});
