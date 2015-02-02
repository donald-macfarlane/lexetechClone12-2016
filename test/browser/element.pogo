retry = require 'trytryagain'
$ = require 'jquery'
chai = require 'chai'
expect = chai.expect
assert = chai.assert
sendkeys = require './sendkeys'
sendclick = require './sendclick'

elementFinder(css, text = nil, ensure = nil, message = nil) =
  cssContains =
    if (text)
      css + ":contains(#(JSON.stringify(text)))"
    else
      css

  {
    find(element) =
      els = $(element).find(cssContains)

      if (els.length > 0)
        if (ensure)
          ensure(els)

        els

    toString() = message @or cssContains
  }

module.exports = prototype {
  addFinder(finder) =
    finders = (self.finders @and self.finders.slice()) @or []
    finders.push (finder)

    self.constructor {
      finders = finders
      element = self.element
    }

  find(args, ...) =
    self.addFinder(elementFinder(args, ...))

  containing(args, ...) =
    finder = elementFinder(args, ...)

    self.addFinder {
      find(element) =
        finder.find(element)
        element
    }

  resolve() =
    printFinders(finders) =
      [f <- finders, f.toString()].join ' / '

    findElement(el, finderIndex) =
      finder = self.finders.(finderIndex)
      if (finder)
        found = finder.find(el)
        assert(found, "expected to find: #(printFinders(self.finders.slice(0, finderIndex + 1)))")
        findElement(found, finderIndex + 1)
      else
        el

    retry!
      els = findElement(self.element, 0)
      expect(els.length).to.equal 1 "expected to find exactly one element: #(printFinders(self.finders))"
      els

  exists() =
    self.resolve()!

  wait(assertion) =
    self.addFinder {
      find(element) =
        assertion(element)
        element
    }.exists!()

  click() =
    sendclick(self.resolve()!.0)

  typeIn(text) =
    sendkeys(self.resolve()!.0, text)
}
