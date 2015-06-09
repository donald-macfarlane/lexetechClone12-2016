var expect = require('chai').expect;
var documentHasChangedStyles = require('../../server/documentHasChangedStyles');

describe('documentHasChangedStyles', function () {
  function lexeme(options) {
    var queryId = options && options.queryId || 1;
    var responseId = options && options.responseId || 1;
    var styles = options && options.styles || {
      style1: 'original',
      style2: 'original'
    };

    function changedStyles(styles) {
      var changed = {};

      Object.keys(styles).forEach(function (key) {
        changed[key] = styles[key] !== 'original';
      });

      return changed;
    }

    return {
      query: {
        id: queryId
      },
      response: {
        id: responseId,
        styles: styles,
        changedStyles: changedStyles(styles)
      }
    };
  }

  context('when there is no original document', function () {
    it('has changed styles when the document contains lexemes with changed styles', function () {
      var document = {
        lexemes: [
          lexeme(),
          lexeme({queryId: '2', responseId: '1', styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme()
        ]
      };

      expect(documentHasChangedStyles(document)).to.eql([
        {queryId: '2', responseId: '1', styles: {style1: 'changed style1', style2: 'changed style2'}}
      ]);
    });

    it('has changed styles when the document contains lexemes with changed styles', function () {
      var document = {
        lexemes: [
          lexeme(),
          lexeme(),
          lexeme()
        ]
      };

      expect(documentHasChangedStyles(document)).to.be.false;
    });
  });

  context('when there is an original document', function () {
    it('is changed when new document has an additional lexeme with changed styles', function () {
      var originalDocument = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme({queryId: 3})
        ]
      };

      var document = {
        lexemes: [
          lexeme({queryId: 1, responseId: '2'}),
          lexeme({queryId: 2, responseId: '3', styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme({queryId: 3, responseId: '1'}),
          lexeme({queryId: 4, responseId: '4', styles: {style1: 'changed style1', style2: 'changed style2'}}),
        ]
      };

      expect(documentHasChangedStyles(document, originalDocument)).to.eql([
        {queryId: 2, responseId: '3', styles: {style1: 'changed style1', style2: 'changed style2'}},
        {queryId: 4, responseId: '4', styles: {style1: 'changed style1', style2: 'changed style2'}}
      ]);
    });

    it('is not changed when new document has an additional lexeme with original styles', function () {
      var originalDocument = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme({queryId: 3})
        ]
      };

      var document = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme({queryId: 3}),
          lexeme({queryId: 4})
        ]
      };

      expect(documentHasChangedStyles(document, originalDocument)).to.be.false;
    });

    it('is changed when new document has changed existing lexeme styles', function () {
      var originalDocument = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, responseId: 3, styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme({queryId: 3})
        ]
      };

      var document = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, responseId: 3, styles: {style1: 'changed style1 (new)', style2: 'changed style2'}}),
          lexeme({queryId: 3})
        ]
      };

      expect(documentHasChangedStyles(document, originalDocument)).to.eql([
        {queryId: 2, responseId: 3, styles: {style1: 'changed style1 (new)'}}
      ]);
    });

    it('is not changed when new document has reverted an existing lexeme style', function () {
      var originalDocument = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, styles: {style1: 'changed style1', style2: 'changed style2'}}),
          lexeme({queryId: 3})
        ]
      };

      var document = {
        lexemes: [
          lexeme({queryId: 1}),
          lexeme({queryId: 2, styles: {style1: 'changed style1', style2: 'original'}}),
          lexeme({queryId: 3})
        ]
      };

      expect(documentHasChangedStyles(document, originalDocument)).to.be.false;
    });
  });
});
