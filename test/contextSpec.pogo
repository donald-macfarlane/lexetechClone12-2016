context = require '../server/context'
expect = require 'chai'.expect

describe 'context'
  describe 'key()'
    itGeneratesDifferentKeyWhen (property) areDifferent (block) =
      itGeneratesDifferentKeyWhen (property) isDifferent (block, plural = true)

    itGeneratesDifferentKeyWhen (property) isDifferent (block, plural = false) =
      it "generates a different key if the #(property) #(if (plural) @{ 'are' } else @{ 'is' }) different"
        a = context {
          level = 1
          blocks = {"1" = true, "3" = true}
          predicants = {"a" = true, "c" = true}
        }

        b = context {
          level = 1
          blocks = {"1" = true, "3" = true}
          predicants = {"a" = true, "c" = true}
        }

        block(b)

        expect(a.key()).to.not.eql(b.key())

    it 'generates the same key if the everything is the same'
      a = context {
        blocks = {"1" = true, "3" = true}
        predicants = {"a" = true, "c" = true}
      }

      b = context {
        blocks = {"1" = true, "3" = true}
        predicants = {"a" = true, "c" = true}
      }

      expect(a.key()).to.eql(b.key())

    itGeneratesDifferentKeyWhen 'level' areDifferent @(c)
      c.level = 2

    itGeneratesDifferentKeyWhen 'blocks' areDifferent @(c)
      delete (c.blocks.1)
      c.blocks.2 = true

    itGeneratesDifferentKeyWhen 'predicants' areDifferent @(c)
      delete (c.predicants.a)
      c.predicants.b = true
