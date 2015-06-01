var removePunctuation = require('../../browser/removePunctuation');
var expect = require('chai').expect;

describe('remove punctuation', function () {
  it('spaces up until the next alpha-numeric', function () {
    expect(removePunctuation('.   Xyz')).to.equal('Xyz');
  });

  it('inside HTML element, spaces up until the next alpha-numeric', function () {
    expect(removePunctuation('<p>.   Xyz</p>')).to.equal('<p>Xyz</p>');
  });

  it('inside HTML elements, spaces up until the next alpha-numeric', function () {
    expect(removePunctuation('<br><p>.   Xyz</p>')).to.equal('<br><p>Xyz</p>');
  });

  it('inside HTML elements with whitespace, spaces up until the next alpha-numeric', function () {
    expect(removePunctuation(' <br>\n<p>\n.   Xyz</p>')).to.equal('<br>\n<p>\nXyz</p>');
  });
});
