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
    undoButton() = self.find('.query button', text = 'undo')
    acceptButton() = self.find('.query button', text = 'accept')
    debugButton() = self.find('input.debug')

    debug() = debugBrowser(self.find('.debug'))
    document() = documentBrowser(self.find('.document'))
    query() = queryElement(self.find '.query')
    responseEditor() = responseEditorElement(self.find('.response-editor'))
  }

  debugBrowser = prototypeExtending(element) {
    block(name) = self.find('li').containing('h3', text = name)
    blockQuery(block, query) = self.block(block).find('.block-query', text = query)
  }

  documentBrowser = prototypeExtending(element) {
    section(text) = self.find('.section', text = text)
  }

  queryElement = prototypeExtending(element) {
    response(text) = responseElement(self.find('.response', text = text))
    queryText() = self.find('.query-text')
  }

  responseElement = prototypeExtending(element) {
    link() = self.find('a')
    editButton() = self.find('button', text = 'edit')
  }

  responseEditorElement = prototypeExtending(element) {
    responseTextEditor(style) = self.find(".tab[data-tab=#(JSON.stringify(style))] .response-text-editor")
    okButton() = self.find('button', text = 'ok')
    cancelButton() = self.find('button', text = 'cancel')
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
    browser.query().queryText().expect!(element.hasText(query))

  shouldBeFinished() =
    retry!
      expect($('.finished').length).to.eql 1

  selectResponse(response) =
    browser.find ".query .response:contains(#(JSON.stringify(response))) a".click!()

  notesShouldBe(notes) =
    retry!
      expect($'.document'.text()).to.eql (notes)

  waitForLexemesToSave(lexemeCount) =
    retry!
      expect(api.documents.length).to.eql(1)
      expect(api.documents.0.lexemes.length).to.eql(lexemeCount)

  context 'with simple lexicon'
    beforeEach
      api.setLexicon (lexicon.blocks [
        {
          id = "1"
          name = "block 1"

          queries = [
            {
              name = 'query1'
              text = 'Where does it hurt?'

              responses = [
                {
                  id = '1'
                  text = 'left leg'

                  styles = {
                    style1 = 'Complaint
                              ---------
                              left leg '
                  }
                }
                {
                  id = '2'
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
                  id = '1'
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
                  id = '1'
                  text = 'yes'

                  styles = {
                    style1 = ', aching'
                  }
                }
              ]
            }
          ]
        }
      ])

      report = reportComponent {user = { email = 'blah@example.com' } }
      plastiq.attach(div, report.render.bind(report))

    it 'can generate notes by answering queries'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding, aching"

    it "as each query is answered, history is stored in the user's document"
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!

      retry!
        expected = [{
          href = '/api/user/documents/1'
          lexemes = [
            {
              query = {
                id = '1'
                name = 'query1'
              }
              context = {
                coherenceIndex = 0
                block = '1'
                blocks = []
                level = 1
                predicants = {}
                blockStack = []
              }
              response = {
                id = '1'
                text = 'left leg'
              }
            }
          ]
        }]
        try
          expect(api.documents).to.eql (expected)
        catch(e)
          console.log('expected', JSON.stringify(expected, nil, 2))
          console.log('actual', JSON.stringify(api.documents, nil, 2))
          throw (e)

      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!

      retry!
        expected = [
          {
            href = '/api/user/documents/1'
            lexemes = [
              {
                query = {
                  id = '1'
                  name = 'query1'
                }
                context = {
                  coherenceIndex = 0
                  block = '1'
                  blocks = []
                  level = 1
                  predicants = {}
                  blockStack = []
                }
                response = {
                  id = '1'
                  text = 'left leg'
                }
              }
              {
                query = {
                  id = '2'
                  name = 'query2'
                }
                context = {
                  coherenceIndex = 1
                  block = '1'
                  blocks = []
                  level = 1
                  predicants = {}
                  blockStack = []
                }
                response = {
                  id = '1'
                  text = 'yes'
                }
              }
            ]
          }
        ]
        try
          expect(api.documents).to.eql (expected)
        catch(e)
          console.log('expected', JSON.stringify(expected, nil, 2))
          console.log('actual', JSON.stringify(api.documents, nil, 2))
          throw (e)

      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      retry!
        expected = [
          {
            href = '/api/user/documents/1'
            lexemes = [
              {
                query = {
                  id = '1'
                  name = 'query1'
                }
                context = {
                  coherenceIndex = 0
                  block = '1'
                  blocks = []
                  level = 1
                  predicants = {}
                  blockStack = []
                }
                response = {
                  id = '1'
                  text = 'left leg'
                }
              }
              {
                query = {
                  id = '2'
                  name = 'query2'
                }
                context = {
                  coherenceIndex = 1
                  block = '1'
                  blocks = []
                  level = 1
                  predicants = {}
                  blockStack = []
                }
                response = {
                  id = '1'
                  text = 'yes'
                }
              }
              {
                query = {
                  id = '3'
                  name = 'query3'
                }
                context = {
                  coherenceIndex = 2
                  block = '1'
                  blocks = []
                  level = 1
                  predicants = {}
                  blockStack = []
                }
                response = {
                  id = '1'
                  text = 'yes'
                }
              }
            ]
          }
        ]
        try
          expect(api.documents).to.eql (expected)
        catch(e)
          console.log('expected', JSON.stringify(expected, nil, 2))
          console.log('actual', JSON.stringify(api.documents, nil, 2))
          throw (e)

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding, aching"

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
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      right leg bleeding, aching"

      waitForLexemesToSave!(3)

    it 'can undo a response, and apply it again'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      browser.find('button', text = 'undo').click!()
      shouldHaveQuery 'Where does it hurt?'!
      browser.query().response('left leg').expect!(element.is('.selected'))
      browser.acceptButton().click!()
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding, aching"

      waitForLexemesToSave!(3)

    it 'can choose another response for a previous query by clicking in the document'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      browser.document().section('bleeding').click!()
      browser.query().response('yes').expect!(element.is('.selected'))
      browser.acceptButton().click!()
      shouldHaveQuery 'Is it aching?'!
      browser.query().response('yes').expect!(element.is('.selected'))
      browser.acceptButton().click!()
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding, aching"

      waitForLexemesToSave!(3)

    it 'can edit the response before accepting it'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      response = browser.query().response('yes')
      response.editButton().click!()
      editor = browser.responseEditor()
      editor.responseTextEditor('style1').typeInHtml!('bleeding badly')
      editor.okButton().click!()
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding badly, aching"

      waitForLexemesToSave!(3)

  context 'lexicon with several blocks'
    beforeEach
      api.setLexicon (lexicon.blocks [
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
                  predicants = ['end']

                  actions = [
                    {
                      name = 'setBlocks'
                      arguments = ['1', '2', '3']
                    }
                  ]

                  styles = {
                    style1 = 'Complaint
                              ---------
                              left leg '
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
          ]
        }
        {
          id = "2"
          name = "block 2"

          queries = [
            {
              name = 'query3'
              text = 'are you dizzy?'
              predicants = ['dizzy']

              responses = [
                {
                  text = 'no'
                }
              ]
            }
          ]
        }
        {
          id = "3"
          name = "block 3"

          queries = [
            {
              name = 'query4'
              text = 'Is it aching?'
              predicants = ['end']

              responses = [
                {
                  text = 'yes'

                  styles = {
                    style1 = 'aching'
                  }
                }
                {
                  text = 'no'
                }
              ]
            }
          ]
        }
      ])

      api.predicants.push({id = 'end', name = 'end'})

      report = reportComponent {user = { email = 'blah@example.com' } }
      plastiq.attach(div, report.render.bind(report))

    it 'displays debugging information' =>
      self.timeout 100000
      browser.debugButton().click!()

      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!

      browser.debug().blockQuery('Block 1', 'query1').expect!(element.is '.before')
      browser.debug().blockQuery('Block 1', 'query2').expect!(element.is '.previous')
      browser.debug().blockQuery('Block 2', 'query3').expect!(element.is '.skipped')
      browser.debug().blockQuery('Block 3', 'query4').expect!(element.is '.found')

      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleedingaching"

      waitForLexemesToSave!(3)
