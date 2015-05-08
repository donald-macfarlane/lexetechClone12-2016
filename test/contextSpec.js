var createContext = require("../browser/context");
var expect = require("chai").expect;

describe("context", function() {
  describe("key()", function() {
    var baseContext;

    function itGeneratesDifferentKeyWhenAreDifferent(property, block) {
      return itGeneratesDifferentKeyWhenIsDifferent(property, block, {
        plural: true
      });
    }

    function itGeneratesDifferentKeyWhenIsDifferent(property, block, options) {
      var plural = options && options.hasOwnProperty("plural") && options.plural !== undefined ? options.plural : false;

      it("generates a different key if the " + property + " " + (plural? 'are': 'is') + " different", function() {
        var b = createContext(JSON.parse(JSON.stringify(baseContext)));
        block(b);
        console.log(b.key());
        expect(baseContext.key()).to.not.eql(b.key());
      });
    }

    it("generates the same key if the everything is the same", function() {
      var a = createContext({
        blocks: {
          "1": true,
          "3": true
        },
        predicants: {
          a: true,
          c: true
        }
      });

      var b = createContext({
        blocks: {
          "1": true,
          "3": true
        },
        predicants: {
          a: true,
          c: true
        }
      });

      expect(a.key()).to.eql(b.key());
    });

    context('simple context', function () {
      beforeEach(function () {
        baseContext = createContext({
          coherenceIndex: 1,
          blocks: {
            "1": true,
            "3": true
          },
          predicants: {
            a: 1,
            c: 2
          }
        });
      });

      itGeneratesDifferentKeyWhenIsDifferent("coherenceIndex", function(c) {
        c.coherenceIndex = 2;
      });

      itGeneratesDifferentKeyWhenAreDifferent("level", function(c) {
        c.level = 2;
      });

      itGeneratesDifferentKeyWhenAreDifferent("blocks", function(c) {
        delete c.blocks[1];
        c.blocks[2] = true;
      });

      itGeneratesDifferentKeyWhenAreDifferent("predicants", function(c) {
        delete c.predicants.a;
      });

      itGeneratesDifferentKeyWhenAreDifferent("predicant values", function(c) {
        c.predicants.a = 3;
      });
    });

    context('context with loop predicants', function () {
      beforeEach(function () {
        baseContext = createContext({
          blocks: {
          },
          predicants: {
          },
          loopPredicants: [
            undefined,
            undefined,
            {
              "a": 5,
              "b": 6,
            }
          ]
        });
      });

      itGeneratesDifferentKeyWhenAreDifferent("loopPredicants", function(c) {
        c.loopPredicants = [];
      });
    });
  });
});
