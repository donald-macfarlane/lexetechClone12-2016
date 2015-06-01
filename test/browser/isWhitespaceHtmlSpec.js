var isWhitespaceHtml = require('../../browser/isWhitespaceHtml');
var expect = require('chai').expect;

describe('is empty html', function () {
  describe('normal whitespace', function () {
    it('returns true if string has only whitespace', function () {
      expect(isWhitespaceHtml(' \n ')).to.be.true;
    });

    it('returns false if string has just one non-whitespace character', function () {
      expect(isWhitespaceHtml(' \n x')).to.be.false;
    });
  });

  describe('HTML tags', function () {
    it('returns true if string has only whitespace or HTML tags', function () {
      expect(isWhitespaceHtml(' \n <p> <br> </p> &nbsp; \n ')).to.be.true;
    });

    it('returns false if string has just one non-whitespace character', function () {
      expect(isWhitespaceHtml(' \n <p> x<br> </p> &nbsp; \n ')).to.be.false;
    });
  });
});
