retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
$ = require 'jquery'
expect = require 'chai'.expect
plastiq = require 'plastiq'
reportComponent = require '../../browser/report'
queryApi = require './queryApi'
lexiconBuilder = require '../lexiconBuilder'
element = require './element'

describe 'report'
  div = nil
  api = nil
  originalLocation = nil
  lexicon = nil
  browser = nil

  reportBrowser = prototypeExtending(element) {
    undoButton() = self.find('button', text = 'undo')
    response(text) = self.find('.response', text = text)
    queryText() = self.find('.query .query-text')
  }

  beforeEach
    div := createTestDiv()
    api := queryApi()
    lexicon := lexiconBuilder()
    originalLocation := location.pathname + location.search + location.hash
    history.pushState(nil, nil, '/')

    browser := reportBrowser {
      element = div
    }

  afterEach
    history.pushState(nil, nil, originalLocation)

  singleElement(css) =
    retry!
      e = $(css)
      expect(e.length).to.eql 1
      e

  shouldHaveQuery(query) =
    browser.queryText().expect!(element.hasText(query))

  shouldBeFinished() =
    retry!
      expect($('.finished').length).to.eql 1

  selectResponse(response) =
    browser.find ".query .response:contains(#(JSON.stringify(response))) a".click!()

  notesShouldBe(notes) =
    retry!
      expect($'.document'.text()).to.eql (notes)

  context 'with simple lexicon'
    beforeEach
      api.blocks.push(lexicon.blocks [
        {
          id = "1"
          name = "block 1"

          queries = [
            {
              name = 'query1'
              text = 'Where does it hurt?'

              responses = [
                {
                  text = 'left leg'

                  styles = {
                    style1 = 'Complaint
                              ---------
                              left leg '
                  }
                }
                {
                  text = 'right leg'

                  styles = {
                    style1 = 'Complaint
                              ---------
                              right leg '
                  }
                }
              ]
            }
            {
              name = 'query2'
              text = 'Is it bleeding?'

              responses = [
                {
                  text = 'yes'

                  styles = {
                    style1 = 'bleeding'
                  }
                }
              ]
            }
            {
              name = 'query3'
              text = 'Is it aching?'

              responses = [
                {
                  text = 'no'
                }
              ]
            }
          ]
        }
      ].blocks, ...)

      report = reportComponent {user = { email = 'blah@example.com' } }
      plastiq.attach(div, report.render.bind(report))

    it 'can generate notes by answering queries'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'no'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding"

    it 'can undo a response, choose a different response'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      browser.find('button', text = 'undo').click!()
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'right leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'no'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      right leg bleeding"

    it 'can undo a response, and apply it again'
