createTestDiv = require './createTestDiv'
$ = require 'jquery'
expect = require 'chai'.expect
sendkeys = require './sendkeys'

describe 'sendkeys'
  itInvokesEvent(eventName, individualKeys: false) =
    it "invokes #(eventName) event"
      div = createTestDiv()

      input = document.createElement('input')
      input.type = 'text'
      div.appendChild(input)

      value = nil
      keys = []

      input.("on#(eventName)")(ev) =
        keys.push(ev.charCode)
        value := ev.target.value

      sendkeys(input, 'blah')

      expect(value).to.equal('blah')
      if (individualKeys)
        expect(keys).to.eql(['b', 'l', 'a', 'h'])

  itInvokesEvent('keyup', individualKeys: true)
  itInvokesEvent('keydown', individualKeys: true)
  itInvokesEvent('keypress', individualKeys: true)
  itInvokesEvent('input')
