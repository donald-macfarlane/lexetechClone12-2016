createTestDiv = require './createTestDiv'
$ = require 'jquery'
expect = require 'chai'.expect
sendclick = require './sendclick'

describe 'sendclick'
  it 'can navigate to an anchor href'
    div = createTestDiv()

    a = document.createElement('a')
    window.location = '#'
    a.href = '#/haha'
    div.appendChild(a)

    sendclick(a)

    expect(window.location.hash).to.equal('#/haha')

  it 'can click on an anchor which prevents default'
    div = createTestDiv()

    a = document.createElement('a')
    window.location = '#'
    a.href = '#/haha'
    div.appendChild(a)

    clicked = false

    div.onclick(ev) =
      clicked := true
      ev.preventDefault()

    sendclick(a)

    expect(clicked).to.be.true
    expect(window.location.hash).to.equal('')
