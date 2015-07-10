retry = require 'trytryagain'
createTestDiv = require './createTestDiv'
sendkeys = require './sendkeys'
sendclick = require './sendclick'
$ = require '../../browser/jquery'
chai = require 'chai'
expect = chai.expect
browser = require 'browser-monkey'
ckeditorMonkey = require './ckeditorMonkey'
authoringComponent = require '../../browser/routes/authoring/blocks/block'
mountApp = require './mountApp'
predicantLexicon = require '../predicantLexicon'
lexiconBuilder = require '../lexiconBuilder'

createRouter = require 'mockjax-router'

queryApi = require './queryApi'

testBrowser = browser.component(ckeditorMonkey)

authoringElement = testBrowser.component {
  dropdownMenu(name) =
    self.find('.btn-group').containing('button.dropdown-toggle', text = name)

  clipboard() =
    self.find('.clipboard')

  clipboardHeader() =
    self.clipboard().find('a', text = 'Clipboard')

  clipboardItem(name) =
    clipboardItem.scope(self.clipboard().find('ol li', text = name))
    
  dropdownMenuItem(name) =
    self.find('ul.dropdown-menu li a', text = name)

  queryMenuItem(blockName, queryName) =
    blockMenuItemMonkey.scope(self.blockMenuItem(blockName).find('.item').containing('> .header', text = queryName))

  blockMenuItem(blockName) =
    blockMenuItemMonkey.scope(self.find('.blocks-queries > .menu > .item').containing('> .header', text = blockName))

  block() =
    self.find('.edit-block')

  blockName() =
    self.find('#block_name')

  createBlockButton() =
    self.find('button', text = 'Create')

  addQueryButton() =
    self.find('button', text = 'Add Query')

  addBlockButton() =
    self.find('button', text = 'Add Block')

  closeBlockButton() =
    self.find('button', text = 'Close')

  editQuery() =
    editQueryMonkey.scope(self.find('.edit-query'))

  responses() =
    responsesElement.scope(self.editQuery().find('ul li.responses'))

  predicantsButton() = self.find('button', text = 'Predicants')
  predicantsEditor() = predicantsEditorComponent.scope(self.find('.predicants-editor'))
}

predicantsEditorComponent = testBrowser.component {
  search() = self.find('.predicant-search input')
  searchResults() = self.find('.predicant-search .results')
  searchResult(name) = self.find('.predicant-search .results a', text = name)
  selectedPredicant() = selectedPredicant.scope(self.find('.selected-predicant'))
}

selectedPredicant = testBrowser.component {
  name() = self.find('input.name')
  saveButton() = self.find('button.save')
  queries() = self.find('.predicant-usages-queries .results > .item')
  responses() = self.find('.predicant-usages-responses .results > .item')
}

blockMenuItemMonkey = testBrowser.component {
  link() = self.find('.header a')
}

editQueryMonkey = testBrowser.component {
  name() = self.find('ul li.name input')
  text() = self.find('ul li.question textarea')
  level() = self.find('ul li.level input')
  predicants() = predicantsMonkey.scope(self.find('ul li div.predicants'))
  addToClipboardButton() = self.find('button', text = 'Add to Clipboard')
  overwriteButton() = self.find('button', text = 'Overwrite')
}

predicantsMonkey = testBrowser.component {
  search() = self.find('input')
  result(name) = self.find('ol li', text = name)
}

clipboardItem = testBrowser.component {
  removeButton() = self.find('.button.remove')
}

responsesElement = testBrowser.component {
  addResponseButton() = self.find('button', text = 'Add Response')
  selectedResponse() = responseElement.scope(self.find('.selected-response'))
}

responseElement = testBrowser.component {
  responseSelector() = self.find('ul li.selector textarea')
  setLevel() = self.find('ul li.set-level input')
  predicantSearch() = self.find('ul li div.predicants input')
  predicant(name) = self.find('ul li div.predicants ol li', text = name)
  style1() = self.find('ul li.style1 .editor')
  style2() = self.find('ul li.style2 .editor')
  actions() = actionsElement.scope(self.find('ul li.actions'))
}

actionsElement = testBrowser.component {
  action(name) = self.find('.dropdown .menu .item', text = name)
  addActionButton() = self.find('.button', text = 'Add Action')
}

describe 'authoring'
  api = nil

  context 'when authoring'
    page = nil
    isKarmaDebug = nil

    before
      isKarmaDebug := window.location.pathname == '/debug.html'

    beforeEach
      page := authoringElement.scope('div.test')

      api := queryApi()

      api.predicants.push {
        id = '1'
        name = 'HemophilVIII'
      }
      api.predicants.push {
        id = '2'
        name = "Hemophilia"
      }

      window.location = '#/authoring'

    startApp() =
      mountApp(authoringComponent(), href = '/authoring')

    after
      if (@not isKarmaDebug)
        mountApp.stop()

    describe 'blocks'

      beforeEach
        startApp()
        page.addBlockButton().click!()
        page.createBlockButton().shouldExist!()
        page.blockName().typeIn!('abcd')
        page.createBlockButton().click!()

      it 'can create a new block'
        retry!
          expect(api.blocks).to.eql [
            {
              id = '1'
              name = 'abcd'
            }
          ]

        page.blockMenuItem('1: abcd').shouldExist()!
        page.blockName().shouldHave(value = 'abcd')!
      
      it 'can create a new query'
        page.closeBlockButton().click!()
        page.addBlockButton().click!()
        page.createBlockButton().shouldExist!()

        page.blockName().shouldHave(value = '')!

        page.blockName().typeIn!('xyz')
        page.createBlockButton().click!()
        page.blockMenuItem('2: xyz').shouldExist()!

        page.addQueryButton().click!()

        editQuery = page.editQuery()
        editQuery.name().typeIn!('query 1')
        editQuery.text().typeIn!('question 1')
        editQuery.level().typeIn!('3')
        editQuery.predicants().search().typeIn!('hemo viii')
        editQuery.predicants().result('HemophilVIII').click!()

        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.selectedResponse()
        newResponse.responseSelector().typeIn!('response 1')
        newResponse.setLevel().typeIn!('4')
        newResponse.predicantSearch().typeIn!('hemo')
        newResponse.predicant('Hemophilia').click!()
        newResponse.style1().typeInCkEditorHtml!(' .<br/>style 1')
        newResponse.style2().typeInCkEditorHtml!(' .<br/>style 2')

        actions = newResponse.actions()
        actions.addActionButton().click!()
        actions.action('Set Blocks').click!()
        actions.find('ol li.action-set-blocks .select-list ol li', text = 'abcd').click!()

        page.find('.edit-query button', text = 'Create').click!()

        retry!
          expect(api.lexicon().blocks.1.queries).to.eql [
            {
              id = "1"
              name = 'query 1'
              text = 'question 1'
              level = 3
              predicants = ["1"]
              responses = [
                {
                  text = 'response 1'
                  predicants = ["2"]
                  styles = {
                    style1 = ".<br />\nstyle 1"
                    style2 = ".<br />\nstyle 2"
                  }
                  actions = [
                    {
                      name = 'setBlocks'
                      arguments = ['1']
                    }
                  ]
                  id = 1
                  setLevel = 4
                }
              ]
            }
          ]

        page.queryMenuItem('xyz', 'query 1').shouldExist!()
      
      it 'can create a query with a user predicant'
        api.users.push {
          id = '1234'
          email = 'joebloggs@example.com'
          firstName = 'Joe'
          familyName = 'Bloggs'
        }

        page.addQueryButton().click!()

        editQuery = page.editQuery()
        editQuery.name().typeIn!('query 1')
        editQuery.text().typeIn!('question 1')
        editQuery.level().typeIn!('3')

        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.selectedResponse()
        newResponse.responseSelector().typeIn!('response 1')
        newResponse.setLevel().typeIn!('4')
        newResponse.predicantSearch().typeIn!('Joe')
        newResponse.predicant('Joe Bloggs').click!()

        page.find('.edit-query button', text = 'Create').click!()

        retry!
          expect(api.lexicon().blocks.0.queries).to.eql [
            {
              id = "1"
              name = 'query 1'
              text = 'question 1'
              level = 3
              predicants = []
              responses = [
                {
                  text = 'response 1'
                  predicants = ["user:1234"]
                  styles = {
                    style1 = ''
                    style2 = ''
                  }
                  actions = []
                  id = 1
                  setLevel = 4
                }
              ]
            }
          ]

    context 'a query with a response'
      beforeEach
        startApp()
        page.addBlockButton().click!()
        page.createBlockButton().shouldExist!()

        page.blockName().typeIn!('xyz')
        page.createBlockButton().click!()

        page.addQueryButton().click!()

        editQuery = page.editQuery()
        responses = page.responses()
        responses.addResponseButton().click!()

      (action) isNotCompatibleWith (disallowedActions) =
        it "disallows creation of #(action) and #(disallowedActions.join(', '))"
          actions = page.responses().selectedResponse().actions()
          actions.addActionButton().click!()

          for each @(actionName) in (disallowedActions)
            actions.action(actionName).shouldExist!()

          actions.action(action).click!()

          for each @(actionName) in (disallowedActions)
            actions.action(actionName).shouldNotExist!()

      describe 'repeat'
        'Repeat' isNotCompatibleWith ['Set Blocks', 'Add Blocks']

      describe 'add blocks'
        'Add Blocks' isNotCompatibleWith ['Set Blocks', 'Add Blocks']

      describe 'set blocks'
        'Set Blocks' isNotCompatibleWith ['Set Blocks', 'Add Blocks']

    describe 'selecting blocks and queries'
      beforeEach
        api.setLexicon({
          blocks = [
            {
              id = '1'
              name = 'one'

              queries = [
                {
                  id = '1'
                  name = 'query 1'
                  text = 'question 1'
                  level = 1
                  predicants = []
                  responses = []
                }
              ]
            }
            {
              id = '2'
              name = 'two'

              queries = [
                {
                  id = '2'
                  name = 'query 2'
                  text = 'question 2'
                  level = 1
                  predicants = []
                  responses = []
                }
              ]
            }
          ]
        })

        startApp()

      it 'can select one block after another'
        page.blockMenuItem('one').link().click!()
        page.blockName().shouldHave!(value = 'one')

        page.blockMenuItem('two').link().click!()
        page.blockName().shouldHave!(value = 'two')

      it 'can select one query after another'
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().shouldHave!(value = 'query 1')

        page.queryMenuItem('two', 'query 2').link().click!()
        page.editQuery().name().shouldHave!(value = 'query 2')

    describe 'updating and inserting queries'
      beforeEach
        api.setLexicon {
          blocks = [
            {
              id = '1'
              name = 'one'

              queries = [
                {
                  id = '1'
                  name = 'query 1'
                  text = 'question 1'
                  level = 1
                  predicants = []
                  responses = [
                    {
                      text = 'response 1'
                      predicants = ["2"]
                      styles = {
                        style1 = '<p>style 1</p>'
                        style2 = '<p>style 2</p>'
                      }
                      actions = [
                        {
                          name = 'setBlocks'
                          arguments = ['1']
                        }
                      ]
                      id = 10
                      setLevel = 4
                    }
                  ]
                }
              ]
            }
          ]
        }

        startApp()
      
      it 'can update a block'
        page.queryMenuItem('one').link().click!()
        page.blockName().typeIn!('one (updated)')
        page.block().find('button', text = 'Save').click!()

        page.blockMenuItem('one (updated)').exists!()

        retry!
          expect([b <- api.blocks, b.name]).to.eql ['one (updated)']
      
      it 'can update a query'
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().typeIn!('query 1 (updated)')
        page.editQuery().find('button', text = 'Overwrite').click!()

        page.queryMenuItem('one', 'query 1 (updated)').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 1 (updated)']
      
      it 'can add a response to a query'
        page.queryMenuItem('one', 'query 1').link().click!()
        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.selectedResponse()
        newResponse.responseSelector().typeIn!('response 2')
        page.editQuery().find('button', text = 'Overwrite').click!()

        retry!
          actual = [r <- api.lexicon().blocks.0.queries.0.responses, {id = r.id, text = r.text}]
          expect(actual).to.eql [
            {
              id = 10
              text = 'response 1'
            }
            {
              id = 11
              text = 'response 2'
            }
          ]
      
      it 'can insert a query before'
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().typeIn!('query 2 (before 1)')
        page.editQuery().find('button', text = 'Insert Before').click!()

        page.queryMenuItem('one', 'query 2 (before 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 2 (before 1)', 'query 1']
      
      it 'can insert a query after'
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().typeIn!('query 2 (after 1)')
        page.editQuery().find('button', text = 'Insert After').click!()

        page.queryMenuItem('one', 'query 2 (after 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 1', 'query 2 (after 1)']
      
      it 'can delete a query'
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().find('button', text = 'Delete').click!()

        page.queryMenuItem('one', 'query 1').shouldNotExist!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, @not q.deleted, q.name]).to.eql []

    describe 'clipboards'
      beforeEach
        api.setLexicon {
          blocks = [
            {
              id = '1'
              name = 'one'

              queries = [
                {
                  id = '1'
                  name = 'query 1'
                  text = 'question 1'
                  level = 1
                  predicants = []
                  responses = []
                }
              ]
            }
          ]
        }
        startApp()

      it 'can add a query to the clipboard'
        page.queryMenuItem('one', 'query 1').link().click()!
        page.editQuery().addToClipboardButton().click()!

        retry!
          expect(api.clipboard).to.eql [
            {
              href = '/api/user/queries/1'
              id = '1'
              name = 'query 1'
              text = 'question 1'
              level = 1
              predicants = []
              responses = []
            }
        ]

        page.clipboardHeader().click()!
        page.clipboardItem('query 1').exists()!

      context 'when there is a query in the clipboard'
        beforeEach
          api.clipboard.push {
            id = '1'
            name = 'query 2'
            text = 'question 1'
            level = 10
            predicants = []
            responses = []
          }
          api.clipboard.push {
            id = '1'
            name = 'query 3'
            text = 'question 2'
            level = 10
            predicants = []
            responses = []
          }
          startApp()

        it 'can paste the query into a new query, not including level'
          page.queryMenuItem('one', 'query 1').link().click()!

          page.editQuery().name().shouldHave!(value: 'query 1')

          page.clipboardHeader().click()!
          page.clipboardItem('query 2').click()!

          page.editQuery().name().shouldHave!(value: 'query 2')
          page.editQuery().level().shouldHave!(value: '1')

          page.editQuery().overwriteButton().click!()
          page.queryMenuItem('one', 'query 2').exists!()

        it 'can delete the clipboard query'
          page.clipboardHeader().click()!
          page.clipboardItem().shouldHave!(text: ['query 2', 'query 3'])
          page.clipboardItem('query 2').removeButton().click()!
          page.clipboardItem().shouldHave!(text: ['query 3'])

    describe 'predicants'
      context 'with a lexicon'
        beforeEach
          lexicon = lexiconBuilder()

          api.predicants.splice(0, api.predicants.length)

          pred1 = {
            id = '1'
            name = 'HemophilVIII'
          }
          pred2 = {
            id = '2'
            name = "Hemophilia"
          }

          api.predicants.push (pred1, pred2)
          console.log('before', api.predicants)

          api.setLexicon (lexicon.queries [
            {
              name = 'query1'
              text = 'All Users Query'

              responses = [
                {
                  id = '1'
                  text = 'User'

                  predicants [pred1.id]
                }
              ]
            }
            {
              name = 'query2'
              text = 'User Query'
              predicants = [pred2.id]

              responses = [
                {
                  id = '1'
                  text = 'Finished'
                }
              ]
            }
          ])

          console.log('after', api.predicants)

          startApp()

        it 'can show and search predicants'
          page.predicantsButton().click()!
          predicantsEditor = page.predicantsEditor()
          predicantsEditor.searchResult().shouldHave(text = ['HemophilVIII', 'Hemophilia'])!
          predicantsEditor.search().typeIn('viii')!
          predicantsEditor.searchResult().shouldHave(text = ['HemophilVIII'])!
          predicantsEditor.searchResult('HemophilVIII').click()!

        it 'can edit and save a predicant'
          page.predicantsButton().click()!
          predicantsEditor = page.predicantsEditor()
          predicantsEditor.searchResult('HemophilVIII').click()!
          predicantsEditor.selectedPredicant().name().shouldHave(value = 'HemophilVIII')!
          predicantsEditor.selectedPredicant().name().typeIn('HemophilVIII (updated)')!
          predicantsEditor.selectedPredicant().saveButton().click()!

          predicantsEditor.searchResult().shouldHave(text = ['HemophilVIII (updated)', 'Hemophilia'])!

          retry!
            expect [p <- api.predicants, p.name].to.eql ['HemophilVIII (updated)', 'Hemophilia']

        it 'predicants show links to queries and responses that contain it'
          page.predicantsButton().click()!
          predicantsEditor = page.predicantsEditor()
          predicantsEditor.searchResult('HemophilVIII').click()!
          predicantsEditor.selectedPredicant().responses().shouldHave(text = ['query1'])!

          predicantsEditor.searchResult('Hemophilia').click()!
          predicantsEditor.selectedPredicant().queries().shouldHave(text = ['query2'])!
