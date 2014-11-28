lexeme = require '../../app/lexeme'
removeTestElement = require './removeTestElement'
$ = require 'jquery'
expect = require 'chai'.expect

describe 'lexeme'
  beforeEach
    removeTestElement()

  it 'renders something'
    div = document.createElement('div')
    div.className = 'test'
    document.body.appendChild(div)

    lexeme(div)

    expect($(div).text()).to.eql 'Welcome to the hospital...'