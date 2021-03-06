window.Promise = require 'bluebird'
retry = require 'trytryagain'
createTestDiv = require './createTestDiv'
$ = require '../../browser/jquery'
expect = require 'chai'.expect
plastiq = require 'plastiq'
mountApp = require './mountApp'
rootComponent = require '../../browser/rootComponent'
queryApi = require './queryApi'
lexiconBuilder = require '../lexiconBuilder'
browser = require 'browser-monkey'
router = require 'plastiq-router'
_ = require 'underscore'
simpleLexicon = require '../simpleLexicon'
omitSkipLexicon = require '../omitSkipLexicon'
repeatingLexicon = require '../repeatingLexicon'
substitutingLexicon = require '../substitutingLexicon'
punctuationLexicon = require '../punctuationLexicon'
predicantLexicon = require '../predicantLexicon'
ckeditorMonkey = require './ckeditorMonkey'
hardstop = require './hardstop'

describe 'enote'
  div = nil
  api = nil
  originalLocation = nil
  lexicon = nil

  testBrowser = browser.find('.test').component(ckeditorMonkey)

  rootBrowser = testBrowser.component {
    newDocumentButton() = self.find('.button', text = 'NEW DOCUMENT')
    enoteTab() = self.find('.ui.button', text = 'eNOTE')
    authoringTab() = self.find('.top-menu .buttons a', text = 'AUTHORING')
    document(name) =
      self.find(".documents tr.document").containing('.name', text: name).component {
        deleteButton() = self.find('.delete.button')
        deleteModal() =
          browser.find('.ui.modals .ui.modal').component {
            okButton() = self.find('.ok.button')
            cancelButton() = self.find('.cancel.button')
          }
      }
  }

  enoteBrowser = testBrowser.component {
    enoteNameInput() = self.find('input.enote-name')
    undoButton() = self.find('.query .button', text = 'UNDO')
    acceptButton() = self.find('.button.accept')
    debugTab() = self.find('.tabular .debug')
    normalTab() = self.find('.tabular .style-normal')
    abbreviatedTab() = self.find('.tabular .style-abbreviated')

    debug() = debugBrowser.scope(self.find('.debug'))
    document() = documentBrowser.scope(self.find('.document'))
    query() = queryElement.scope(self.find '.query')
    queryText() = self.find('.query-text')
    responseEditor() = self.find('.response-editor').component(responseEditorElement)
  }

  debugBrowser = testBrowser.component {
    block(name) = self.find('li').containing('h3', text = name)
    blockQuery(block, query) = self.block(block).find('.block-query', text = query)
  }

  documentBrowser = testBrowser.component {
    section(text) = self.find('.section', text = text)
  }

  queryElement = testBrowser.component {
    response(text) = responseElement.scope(self.find('.response', text = text))
    skipButton() = self.find('.button.skip')
    omitButton() = self.find('.button.omit')
  }

  responseElement = testBrowser.component {
    link() = self.find('a')
    editButton() = self.find('button', text = 'edit')
    shouldBeSelected() = self.shouldHave!(css = '.selected')
    shouldBeChecked() = self.shouldHave!(css = '.checked')
  }

  responseEditorElement = {
    tab(style) = self.find(".ui.tabular.menu a.item.style-#(style)")
    responseTextEditor(style) = self.find(".tab.style-#(style) .response-text-editor")
    okButton() = self.find('button', text = 'OK')
    cancelButton() = self.find('button', text = 'cancel')
  }

  beforeEach
    hardstop.start()
    div := createTestDiv()
    api := queryApi()
    lexicon := lexiconBuilder()
    originalLocation := location.pathname + location.search + location.hash

  afterEach
    hardstop.stop()

  after
    mountApp.stop()

  singleElement(css) =
    retry!
      e = $(css)
      expect(e.length).to.eql 1
      e

  shouldHaveQuery(query) =
    enoteBrowser.queryText().shouldHave!(text: query.toUpperCase())

  shouldBeFinished() =
    retry!
      enoteBrowser.find('.finished').exists!()

  selectResponse(response) =
    enoteBrowser.find ".query .response a" (text = response).click!()

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

    mountApp(rootComponent(options), href = '/')

  context 'with simple lexicon'
    beforeEach
      api.setLexicon (simpleLexicon())
      appendRootComponent()
      rootBrowser.newDocumentButton().click!()

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
      enoteBrowser.undoButton().click!()
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
      enoteBrowser.undoButton().click!()
      shouldHaveQuery 'Where does it hurt?'!
      enoteBrowser.query().response('left leg').shouldBeSelected()!
      enoteBrowser.acceptButton().click!()
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
      enoteBrowser.document().section('bleeding').click!()
      shouldHaveQuery 'Is it bleeding?'!
      enoteBrowser.query().response('yes').shouldBeSelected()!
      enoteBrowser.acceptButton().click!()
      shouldHaveQuery 'Is it aching?'!
      enoteBrowser.query().response('yes').shouldBeSelected()!
      enoteBrowser.acceptButton().click!()
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

      enoteBrowser.abbreviatedTab().click!()

      notesShouldBe! "lft leg, bleed, ache"

      waitForLexemesToSave!(3)

    it 'can edit the response before accepting it'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      response = enoteBrowser.query().response('yes')
      response.editButton().click!()
      editor = enoteBrowser.responseEditor()
      style1Editor = editor.responseTextEditor('style1')
      style1Editor.typeInCkEditorHtml!('bleeding badly')
      style1Tab = editor.tab('style1')
      style1Tab.shouldHave!(css: '.edited')

      editor.okButton().click!()
      shouldHaveQuery 'Is it aching?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "Complaint
                      ---------
                      left leg bleeding badly, aching"

      waitForLexemesToSave!(3)

  context 'with authoring access'
    beforeEach
      api.setLexicon (simpleLexicon())
      appendRootComponent(user = {email = 'bob@example.com', author = true})
      rootBrowser.newDocumentButton().click!()

    it 'can navigate to author the current query'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!

      rootBrowser.authoringTab().click()!
      rootBrowser.find('.edit-query .name input').shouldHave(value = 'query2')!

  context 'lexicon that sets variables'
    beforeEach
      api.setLexicon (substitutingLexicon())
      appendRootComponent()
      rootBrowser.newDocumentButton().click!()

    it 'outputs the document with variables substituted'
      shouldHaveQuery 'Patient gender'!
      selectResponse 'Female'!
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldBeFinished()!

      notesShouldBe! "She complains that her left leg is bleeding"

      waitForLexemesToSave!(3)

  context 'lexicon that suppresses punctuation'
    beforeEach
      api.setLexicon (punctuationLexicon())
      appendRootComponent()
      rootBrowser.newDocumentButton().click!()

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
              id = '1'
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
              id = '2'
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
              id = '3'
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

      mountApp(rootComponent {
        user = { email = 'blah@example.com' }
        graphHack = false
      }, href = '/')

      rootBrowser.newDocumentButton().click!()

    it 'displays debugging information' =>
      self.timeout 100000
      enoteBrowser.debugTab().click!()

      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      selectResponse 'yes'!
      shouldHaveQuery 'Is it aching?'!

      enoteBrowser.debug().blockQuery('Block 1', 'query1').shouldHave!(css: '.before')
      enoteBrowser.debug().blockQuery('Block 1', 'query2').shouldHave!(css: '.previous')
      enoteBrowser.debug().blockQuery('Block 2', 'query3').shouldHave!(css: '.skipped')
      enoteBrowser.debug().blockQuery('Block 3', 'query4').shouldHave!(css: '.found')

      selectResponse 'yes'!
      shouldBeFinished()!

      enoteBrowser.normalTab().click!()

      notesShouldBe! "Complaint
                      ---------
                      left leg bleedingaching"

      waitForLexemesToSave!(3)

  context 'logged in with simple lexicon'
    beforeEach
      api.setLexicon (simpleLexicon())
      appendRootComponent()

    it 'can create a new document'
      rootBrowser.newDocumentButton().click!()
      shouldHaveQuery 'Where does it hurt?'!

    describe 'documents'
      it 'can create a document, make some responses, and come back to it'
        retry!
          expect(api.documents.length).to.eql 0

        rootBrowser.newDocumentButton().click!()
        enoteBrowser.enoteNameInput().typeIn!("bob's enote")
        shouldHaveQuery 'Where does it hurt?'!
        selectResponse 'left leg'!
        shouldHaveQuery 'Is it bleeding?'!

        retry!
          expect(api.documents.length).to.eql 1

        history.back()

        bobsEnote = rootBrowser.document("bob's enote")
        bobsEnote.shouldExist!()

        bobsEnote.click!()
        shouldHaveQuery 'Is it bleeding?'!
        selectResponse 'yes'!
        shouldHaveQuery 'Is it aching?'!
        selectResponse 'yes'!
        enoteBrowser.enoteNameInput().shouldHave!(value: "bob's enote")
        shouldBeFinished()!

      it 'can create a document and delete it'
        retry!
          expect(api.documents.length).to.eql 0

        rootBrowser.newDocumentButton().click!()
        enoteBrowser.enoteNameInput().typeIn!("bob's enote")
        shouldHaveQuery 'Where does it hurt?'!
        selectResponse 'left leg'!
        shouldHaveQuery 'Is it bleeding?'!

        retry!
          expect(api.documents.length).to.eql 1

        history.back()

        bobsEnote = rootBrowser.document("bob's enote")
        bobsEnote.shouldExist!()
        bobsEnote.deleteButton().click()!
        bobsEnote.deleteModal().okButton().click()!
        bobsEnote.shouldNotExist!()

      it 'can create a document come back to it using the enote link'
        retry!
          expect(api.documents.length).to.eql 0

        rootBrowser.newDocumentButton().click!()
        enoteBrowser.enoteNameInput().typeIn!("bob's enote")
        shouldHaveQuery 'Where does it hurt?'!
        selectResponse 'left leg'!
        shouldHaveQuery 'Is it bleeding?'!

        retry!
          expect(api.documents.length).to.eql 1

        history.back()

        rootBrowser.enoteTab().click()!
        enoteBrowser.enoteNameInput().shouldHave!(value: "bob's enote")

      it 'can create a document, make some repeating responses, and come back to it'
        retry!
          expect(api.documents.length).to.eql 0

        rootBrowser.newDocumentButton().click!()
        enoteBrowser.enoteNameInput().typeIn!("bob's enote")
        shouldHaveQuery 'Where does it hurt?'!
        selectResponse 'left leg'!
        shouldHaveQuery 'Is it bleeding?'!
        response = enoteBrowser.query().response('yes')
        response.editButton().click!()
        editor = enoteBrowser.responseEditor()
        editor.responseTextEditor('style1').typeInCkEditorHtml!('bleeding badly')
        editor.okButton().click!()
        shouldHaveQuery 'Is it aching?'!

        retry!
          expect(api.documents.length).to.eql 1

        window.history.back()

        bobsEnote = rootBrowser.document("bob's enote")
        bobsEnote.shouldExist!()

        bobsEnote.click!()
        shouldHaveQuery 'Is it aching?'!
        enoteBrowser.undoButton().click!()
        shouldHaveQuery 'Is it bleeding?'!

        response.editButton().click!()

        editor.responseTextEditor('style1').shouldHave!(html: 'bleeding badly')

        editor.okButton().click!()

        shouldHaveQuery 'Is it aching?'!
        selectResponse 'yes'!
        shouldBeFinished()!

      context 'given a existing document with some style changes'
        beforeEach
          retry!
            expect(api.documents.length).to.eql 0

          rootBrowser.newDocumentButton().click!()
          enoteBrowser.enoteNameInput().typeIn!("bob's enote")
          shouldHaveQuery 'Where does it hurt?'!
          selectResponse 'left leg'!
          shouldHaveQuery 'Is it bleeding?'!
          response = enoteBrowser.query().response('yes')
          response.editButton().click!()
          editor = enoteBrowser.responseEditor()
          editor.responseTextEditor('style1').typeInCkEditorHtml!('bleeding badly')
          editor.okButton().click!()
          shouldHaveQuery 'Is it aching?'!

          retry!
            expect(api.documents.length).to.eql 1
            expect(api.documents.0.lexemes.length).to.eql 2

          window.history.back()

        it 'reloads the document and updates styles from new lexicon'
          api.queriesById.(1).responses.(0).styles.style1 = 'the left leg '

          retry!
            expect(api.documents.length).to.eql 1
            expect(api.documents.0.lexemes.length).to.eql 2
            expect(api.documents.0.lexemes.0.response.styles.style1).to.equal "Complaint\n---------\nleft leg "

          rootBrowser.document("bob's enote").click!()

          notesShouldBe! "the left leg bleeding badly"

          retry!
            expect(api.documents.length).to.eql 1
            expect(api.documents.0.lexemes.length).to.eql 2
            expect(api.documents.0.lexemes.0.response.styles.style1).to.equal 'the left leg '

  context 'logged in with lexicon with user specific queries'
    beforeEach
      api.setLexicon (predicantLexicon('user:1234'))

    context 'when the right user is logged in'
      beforeEach
        appendRootComponent {
          user = { email = 'blah@example.com', id = '1234' }
        }
        rootBrowser.newDocumentButton().click!()

      it "shows the query for the user"
        shouldHaveQuery 'All Users Query'!
        selectResponse 'User'!
        shouldHaveQuery 'User Query'!
        selectResponse 'Finished'!
        shouldBeFinished()!

    context "when the user isn't logged in"
      beforeEach
        appendRootComponent {
          user = { email = 'another@example.com', id = '5678' }
        }
        rootBrowser.newDocumentButton().click!()

      it "doesn't show the query for the other user"
        shouldHaveQuery 'All Users Query'!
        selectResponse 'User'!
        shouldBeFinished()!

  context 'logged in with repeating lexicon'
    beforeEach
      api.setLexicon (repeatingLexicon())
      appendRootComponent()

    it 'can create a document, make some repeating responses, and come back to it'
      retry!
        expect(api.documents.length).to.eql 0

      rootBrowser.newDocumentButton().click!()
      enoteBrowser.enoteNameInput().typeIn!("bob's enote")
      shouldHaveQuery 'One'!
      selectResponse 'A'!
      shouldHaveQuery 'One'!
      selectResponse 'C'!
      shouldHaveQuery 'One'!

      retry!
        expect(api.documents.length).to.eql 1

      window.history.back()

      bobsEnote = rootBrowser.document("bob's enote")
      bobsEnote.shouldExist!()

      bobsEnote.click!()
      shouldHaveQuery 'One'!
      enoteBrowser.query().response('A').shouldBeChecked()!
      enoteBrowser.query().response('C').shouldBeChecked()!
      selectResponse 'No More'!
      shouldBeFinished()!

  context 'logged in with lexicon for omit + skip'
    beforeEach
      api.setLexicon (omitSkipLexicon())
      appendRootComponent()
      rootBrowser.newDocumentButton().click!()
      
    it 'can omit'
      shouldHaveQuery 'query 1, level 1'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 2, level 1'!
      enoteBrowser.query().omitButton().click!()
      shouldHaveQuery 'query 3, level 2'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 5, level 1'!
      selectResponse 'response 1'!
      shouldBeFinished()!
      
    it 'can omit go back and accept the omit again'
      shouldHaveQuery 'query 1, level 1'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 2, level 1'!
      enoteBrowser.query().omitButton().click!()
      shouldHaveQuery 'query 3, level 2'!
      enoteBrowser.undoButton().click!()
      shouldHaveQuery 'query 2, level 1'!
      enoteBrowser.query().omitButton().shouldHave!(css: '.selected')
      enoteBrowser.acceptButton().click!()
      shouldHaveQuery 'query 3, level 2'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 5, level 1'!
      selectResponse 'response 1'!
      shouldBeFinished()!
      
    it 'can skip'
      shouldHaveQuery 'query 1, level 1'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 2, level 1'!
      enoteBrowser.query().skipButton().click!()
      shouldHaveQuery 'query 5, level 1'!
      selectResponse 'response 1'!
      shouldBeFinished()!
      
    it 'can skip go back and accept the skip again'
      shouldHaveQuery 'query 1, level 1'!
      selectResponse 'response 1'!
      shouldHaveQuery 'query 2, level 1'!
      enoteBrowser.query().skipButton().click!()
      shouldHaveQuery 'query 5, level 1'!
      enoteBrowser.undoButton().click!()
      shouldHaveQuery 'query 2, level 1'!
      enoteBrowser.query().skipButton().shouldHave!(css: '.selected')
      enoteBrowser.acceptButton().click!()
      shouldHaveQuery 'query 5, level 1'!
      selectResponse 'response 1'!
      shouldBeFinished()!
