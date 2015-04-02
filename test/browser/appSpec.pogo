retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
$ = require '../../browser/jquery'
expect = require 'chai'.expect
plastiq = require 'plastiq'
rootComponent = require '../../browser/root'
queryApi = require './queryApi'
lexiconBuilder = require '../lexiconBuilder'
element = require './element'

describe 'report'
  div = nil
  api = nil
  originalLocation = nil
  lexicon = nil
  simpleLexicon = nil
  reportBrowser = nil
  rootBrowser = nil

  createRootBrowser = prototypeExtending(element) {
    startNewButton() = self.find('.button', text = 'Start new document')
    loadPreviousButton() = self.find('.button', text = 'Load previous document')
  }

  createReportBrowser = prototypeExtending(element) {
    undoButton() = self.find('.query button', text = 'undo')
    acceptButton() = self.find('.query button', text = 'accept')
    debugTab() = self.find('.tabular .debug')

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

    simpleLexicon := lexicon.blocks [
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
    ]

    rootBrowser := createRootBrowser {
      element = div
    }

    reportBrowser := createReportBrowser {
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

  context 'with simple lexicon'
    beforeEach
      api.setLexicon (simpleLexicon)

      root = rootComponent {user = { email = 'blah@example.com' }, graphHack = false}
      plastiq.append(div, root.render.bind(root))

      rootBrowser.startNewButton().click!()

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

      it 'can create a new document'
        

    it 'can undo a response, choose a different response'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      reportBrowser.find('button', text = 'undo').click!()
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
      reportBrowser.find('button', text = 'undo').click!()
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

    it 'can edit the response before accepting it'
      shouldHaveQuery 'Where does it hurt?'!
      selectResponse 'left leg'!
      shouldHaveQuery 'Is it bleeding?'!
      response = reportBrowser.query().response('yes')
      response.editButton().click!()
      editor = reportBrowser.responseEditor()
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

      root = rootComponent {user = { email = 'blah@example.com' }, graphHack = false}
      plastiq.append(div, root.render.bind(root))

      rootBrowser.startNewButton().click!()

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

      notesShouldBe! "Complaint
                      ---------
                      left leg bleedingaching"

      waitForLexemesToSave!(3)
