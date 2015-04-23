retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
$ = require '../../browser/jquery'
expect = require 'chai'.expect
plastiq = require 'plastiq'
rootComponent = require '../../browser/rootComponent'
queryApi = require './queryApi'
lexiconBuilder = require '../lexiconBuilder'
element = require './element'
router = require 'plastiq-router'
_ = require 'underscore'
simpleLexicon = require '../simpleLexicon'
omitSkipLexicon = require '../omitSkipLexicon'
repeatingLexicon = require '../repeatingLexicon'
substitutingLexicon = require '../substitutingLexicon'
punctuationLexicon = require '../punctuationLexicon'

describe 'report'
  div = nil
  api = nil
  originalLocation = nil
  lexicon = nil
  reportBrowser = nil
  rootBrowser = nil

  createRootBrowser = prototypeExtending(element) {
    startNewDocumentButton() = self.find('.button', text = 'Start new document')
    loadCurrentDocumentButton() = self.find('.button', text = 'Load current document')
    loadPreviousButton() = self.find('.button', text = 'Load previous document')
  }

  createReportBrowser = prototypeExtending(element) {
    undoButton() = self.find('.query button', text = 'undo')
    acceptButton() = self.find('.query button', text = 'accept')
    debugTab() = self.find('.tabular .debug')
    normalTab() = self.find('.tabular .style-normal')
    abbreviatedTab() = self.find('.tabular .style-abbreviated')

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
    skipButton() = self.find('button.skip')
    omitButton() = self.find('button.omit')
    queryText() = self.find('.query-text')
  }

  responseElement = prototypeExtending(element) {
    link() = self.find('a')
    editButton() = self.find('button', text = 'edit')
  }

  responseEditorElement = prototypeExtending(element) {
    tab(style) = self.find(".ui.tabular.menu a.item.style-#(style)")
    responseTextEditor(style) = self.find(".tab.style-#(style) .response-text-editor")
    okButton() = self.find('button', text = 'ok')
    cancelButton() = self.find('button', text = 'cancel')
  }

  beforeEach
    div := createTestDiv()
    api := queryApi()
    lexicon := lexiconBuilder()
    originalLocation := location.pathname + location.search + location.hash
    history.pushState(nil, nil, '/')

    rootBrowser := createRootBrowser {
      element = div
    }

    reportBrowser := createReportBrowser {
      element = div
    }

  afterEach
    history.pushState(nil, nil, originalLocation)

  after
    router.stop()

  singleElement(css) =
    retry!
      e = $(css)
      expect(e.length).to.eql 1
      e

  shouldHaveQuery(query) =
    reportBrowser.query().queryText().expect!(element.hasText(query))

  shouldBeFinished() =
    retry!
      reportBrowser.find('.finished').exists!()

  selectResponse(response) =
    reportBrowser.find ".query .response:contains(#(JSON.stringify(response))) a".click!()

  notesShouldBe(notes) =
    retry!
      expect($'.document'.text()).to.eql (notes)

  waitForLexemesToSave(lexemeCount) =
    retry!
      expect(api.documents.length).to.eql(1)
      expect(api.documents.0.lexemes.length).to.eql(lexemeCount)

  appendRootComponent (options) =
    options := _.extend {
      user = { email = 'blah@example.com' }
      graphHack = false
    } (options)

    root = rootComponent(options)
    plastiq.append(div, root.render.bind(root))

  context 'with simple lexicon'
    beforeEach
      api.setLexicon (simpleLexicon())
      appendRootComponent()
      rootBrowser.startNewDocumentButton().click!()

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

    describe 'documents'
      it "as each query is answered, history is stored in the user's document"
        shouldHaveQuery 'Where does it hurt?'!
        selectResponse 'left leg'!

        simplifyDocuments(docs) =
          docs.map @(doc)
            doc.lexemes.map @(lexeme)
              {
                query = lexeme.query.id
                response = lexeme.response.id
              }

        retry!
          expect(simplifyDocuments(api.documents)).to.eql [
            [
              { query = '1', response = '1' }
            ]
          ]

        shouldHaveQuery 'Is it bleeding?'!
        selectResponse 'yes'!

        retry!
          expect(simplifyDocuments(api.documents)).to.eql [
            [
              { query = '1', response = '1' }
              { query = '2', response = '1' }
            ]
          ]

        shouldHaveQuery 'Is it aching?'!
        selectResponse 'yes'!
        shouldBeFinished()!

        retry!
          expect(simplifyDocuments(api.documents)).to.eql [
            [
              { query = '1', response = '1' }
              { query = '2', response = '1' }
              { query = '3', response = '1' }
            ]
          ]

        notesShouldBe! "Complaint
                        ---------
                        left leg bleeding, aching"

    it 'can undo a response, choose a different response'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      reportBrowser.undoButton().click!()
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
      reportBrowser.undoButton().click!()
      shouldHaveQuery 'Where does it hurt?'!
      reportBrowser.query().response('left leg').expect!(element.is('.selected'))
      reportBrowser.acceptButton().click!()
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
      reportBrowser.document().section('bleeding').click!()
      shouldHaveQuery 'Is it bleeding?'!
      reportBrowser.query().response('yes').expect!(element.is('.selected'))
      reportBrowser.acceptButton().click!()
      shouldHaveQuery 'Is it aching?'!
      reportBrowser.query().response('yes').expect!(element.is('.selected'))
      reportBrowser.acceptButton().click!()
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding, aching"

      waitForLexemesToSave!(3)

    it 'can see the abbreviated version of the document'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      reportBrowser.abbreviatedTab().click!()

      notesShouldBe! "lft leg, bleed, ache"

      waitForLexemesToSave!(3)

    it 'can edit the response before accepting it'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      response = reportBrowser.query().response('yes')
      response.editButton().click!()
      editor = reportBrowser.responseEditor()
      style1Editor = editor.responseTextEditor('style1')
      style1Editor.typeInHtml!('bleeding badly')
      style1Tab = editor.tab('style1')
      style1Tab.expect! @(el)
        el.has('.edited')
        
      editor.okButton().click!()
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding badly, aching"

      waitForLexemesToSave!(3)

  context 'lexicon that sets variables'
    beforeEach
      api.setLexicon (substitutingLexicon())
      appendRootComponent()
      rootBrowser.startNewDocumentButton().click!()

    it 'outputs the document with variables substituted'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "bleeding left leg, aching"

      waitForLexemesToSave!(3)

  context 'lexicon that suppresses punctuation'
    beforeEach
      api.setLexicon (punctuationLexicon())
      appendRootComponent()
      rootBrowser.startNewDocumentButton().click!()

    it 'outputs the document with variables substituted'
      shouldHaveQuery 'Heading'!
      selectResponse 'One'!
      shouldHaveQuery 'Sentence'!
      selectResponse 'One'!
      shouldBeFinished()!

      notesShouldBe! "Heading OneThis is the beginning of a sentence"

      waitForLexemesToSave!(2)

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

      root = rootComponent {user = { email = 'blah@example.com' }, graphHack = false}
      plastiq.append(div, root.render.bind(root))

      rootBrowser.startNewDocumentButton().click!()

    it 'displays debugging information' =>
      self.timeout 100000
      reportBrowser.debugTab().click!()

      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!

      reportBrowser.debug().blockQuery('Block 1', 'query1').expect!(element.is '.before')
      reportBrowser.debug().blockQuery('Block 1', 'query2').expect!(element.is '.previous')
      reportBrowser.debug().blockQuery('Block 2', 'query3').expect!(element.is '.skipped')
      reportBrowser.debug().blockQuery('Block 3', 'query4').expect!(element.is '.found')

      selectResponse 'yes'!
      shouldBeFinished()!

      reportBrowser.normalTab().click!()

      notesShouldBe! "Complaint
                      ---------
                      left leg bleedingaching"

      waitForLexemesToSave!(3)

  context 'logged in with simple lexicon'
    beforeEach
      api.setLexicon (simpleLexicon())
      appendRootComponent()

    it 'can create a new document'
      rootBrowser.loadCurrentDocumentButton().has('.disabled').exists!()
      rootBrowser.startNewDocumentButton().click!()
      shouldHaveQuery 'Where does it hurt?'!

    it 'can create a document, make some responses, and come back to it'
      retry!
        expect(api.documents.length).to.eql 0

      rootBrowser.startNewDocumentButton().click!()
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!

      retry!
        expect(api.documents.length).to.eql 1

      window.history.back()

      rootBrowser.loadCurrentDocumentButton().expect! @(element)
        @not element.has '.disabled'

      rootBrowser.loadCurrentDocumentButton().click!()
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

  context 'logged in with simple lexicon'
    beforeEach
      api.setLexicon (simpleLexicon())
      appendRootComponent()

    it 'can create a document, make some repeating responses, and come back to it'
      retry!
        expect(api.documents.length).to.eql 0

      rootBrowser.startNewDocumentButton().click!()
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      response = reportBrowser.query().response('yes')
      response.editButton().click!()
      editor = reportBrowser.responseEditor()
      editor.responseTextEditor('style1').typeInHtml!('bleeding badly')
      editor.okButton().click!()
      shouldHaveQuery 'Is it aching?'!

      retry!
        expect(api.documents.length).to.eql 1

      window.history.back()

      rootBrowser.loadCurrentDocumentButton().expect! @(element)
        @not element.has '.disabled'

      rootBrowser.loadCurrentDocumentButton().click!()
      shouldHaveQuery 'Is it aching?'!
      reportBrowser.undoButton().click!()
      shouldHaveQuery 'Is it bleeding?'!

      response.editButton().click!()

      editor.responseTextEditor('style1').expect! @(element)
        element.html() == 'bleeding badly'

      editor.okButton().click!()

      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

  context 'logged in with repeating lexicon'
    beforeEach
      api.setLexicon (repeatingLexicon())
      appendRootComponent()

    it 'can create a document, make some repeating responses, and come back to it'
      retry!
        expect(api.documents.length).to.eql 0

      rootBrowser.startNewDocumentButton().click!()
      shouldHaveQuery 'One'!
      selectResponse 'A'!
      shouldHaveQuery 'One'!
      selectResponse 'C'!
      shouldHaveQuery 'One'!

      retry!
        expect(api.documents.length).to.eql 1

      window.history.back()

      rootBrowser.loadCurrentDocumentButton().expect! @(element)
        @not element.has '.disabled'

      rootBrowser.loadCurrentDocumentButton().click!()
      shouldHaveQuery 'One'!
      reportBrowser.query().response('A').expect!(element.is('.other'))
      reportBrowser.query().response('C').expect!(element.is('.other'))
      selectResponse 'No More'!
      shouldBeFinished()!

  context 'logged in with lexicon for omit + skip'
    beforeEach
      api.setLexicon (omitSkipLexicon())
      appendRootComponent()
      rootBrowser.startNewDocumentButton().click!()
      
    it 'can omit'
      shouldHaveQuery 'query 1, level 1'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 2, level 1'!
      reportBrowser.query().omitButton().click!()
      shouldHaveQuery 'query 3, level 2'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 5, level 1'!
      selectResponse 'response 1'!
      shouldBeFinished()!
      
    it 'can skip'
      shouldHaveQuery 'query 1, level 1'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 2, level 1'!
      reportBrowser.query().skipButton().click!()
      shouldHaveQuery 'query 5, level 1'!
      selectResponse 'response 1'!
      shouldBeFinished()!
