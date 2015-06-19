retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
sendkeys = require './sendkeys'
sendclick = require './sendclick'
$ = require '../../browser/jquery'
chai = require 'chai'
expect = chai.expect
browser = require 'browser-monkey'
ckeditorMonkey = require './ckeditorMonkey'

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
    self.blockMenuItem(blockName).find('ol li', message = "query #(JSON.stringify(queryName))").containing('> h4', text = queryName)

  blockMenuItem(blockName) =
    self.find('.blocks-queries ol li', text = blockName, message = "block #(JSON.stringify(blockName))")

  block() =
    self.find('.edit-block')

  blockName() =
    self.find('#block_name')

  query() =
    self.find('.edit-query')

  queryName() =
    self.find('.edit-query ul li.name input')

  responses() =
    responsesElement.scope(self.query().find('ul li.responses'))
  
  actions() =
    self.responses().find('ul li.actions')

  action(name) =
    self.actions().find('ul.dropdown-menu li a', text = name)
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
}

describe 'authoring'
  div = nil
  api = nil

  context 'when authoring'
    page = nil

    beforeEach
      div := createTestDiv()
      page := authoringElement.scope(div)

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
      lexeme(div, {}, { user = { email = 'blah@example.com'} }, { historyApi = false })

    describe 'blocks'

      beforeEach
        startApp()
        page.find('button', text = 'Add Block').click!()
        page.find('#block_name').typeIn!('abcd')
        page.find('button', text = 'Create').click!()

      it 'can create a new block'
        retry!
          expect(api.blocks).to.eql [
            {
              id = '1'
              name = 'abcd'
            }
          ]

        page.find('.blocks-queries ol li:contains("1: abcd")').exists()!
        page.find('#block_name', ensure(e) = expect(e.val()).to.equal('abcd')).exists!()
      
      it 'can create a new query'
        page.find('button', text = 'Close').exists!()
        page.find('button', text = 'Add Block').click!()

        page.find('#block_name', ensure(el) = expect(el.val()).to.equal '').exists()!

        page.find('#block_name').typeIn!('xyz')
        page.find('button', text = 'Create').click!()

        page.find('button', text = 'Add Query').click!()

        editQuery = page.find('.edit-query')
        editQuery.find('ul li.name input').typeIn!('query 1')
        editQuery.find('ul li.question textarea').typeIn!('question 1')
        editQuery.find('ul li.level input').typeIn!('3')
        editQuery.find('ul li div.predicants input').typeIn!('hemo viii')
        editQuery.find('ul li div.predicants ol li', text = 'HemophilVIII').click!()

        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.selectedResponse()
        newResponse.responseSelector().typeIn!('response 1')
        newResponse.setLevel().typeIn!('4')
        newResponse.predicantSearch().typeIn!('hemo')
        newResponse.predicant('Hemophilia').click!()
        newResponse.style1().typeInCkEditorHtml!(' .<br/>style 1')
        newResponse.style2().typeInCkEditorHtml!(' .<br/>style 2')

        actions = responses.find('ul li.actions')
        actions.find('button', text = 'Add Action').click!()
        actions.find('ul.dropdown-menu li a', text = 'Set Blocks').click!()
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

        page.queryMenuItem('xyz', 'query 1').exists!()
      
      it 'can create a query with a user predicant'
        api.users.push {
          id = '1234'
          email = 'joebloggs@example.com'
          firstName = 'Joe'
          familyName = 'Bloggs'
        }

        page.find('button', text = 'Add Query').click!()

        editQuery = page.find('.edit-query')
        editQuery.find('ul li.name input').typeIn!('query 1')
        editQuery.find('ul li.question textarea').typeIn!('question 1')
        editQuery.find('ul li.level input').typeIn!('3')

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
        page.find('button', text = 'Add Block').click!()

        page.find('#block_name', ensure(el) = expect(el.val()).to.equal '').exists()!

        page.find('#block_name').typeIn!('xyz')
        page.find('button', text = 'Create').click!()

        page.find('button', text = 'Add Query').click!()

        editQuery = page.find('.edit-query')
        responses = page.responses()
        responses.addResponseButton().click!()

      (action) isNotCompatibleWith (disallowedActions) =
        it "disallows creation of #(action) and #(disallowedActions.join(', '))"
          actions = page.actions()
          actions.find('button', text = 'Add Action').click!()

          for each @(actionName) in (disallowedActions)
            page.action(actionName).shouldExist!()

          page.action(action).click!()

          for each @(actionName) in (disallowedActions)
            page.action(actionName).shouldNotExist!()

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
        page.blockMenuItem('one').find('h3').click!()
        page.blockName().shouldHave!(value = 'one')

        page.blockMenuItem('two').find('h3').click!()
        page.blockName().shouldHave!(value = 'two')

      it 'can select one query after another'
        page.queryMenuItem('one', 'query 1').find('h4').click!()
        page.queryName().shouldHave!(value = 'query 1')

        page.queryMenuItem('two', 'query 2').find('h4').click!()
        page.queryName().shouldHave!(value = 'query 2')

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
        page.queryMenuItem('one').find('h4').click!()
        page.blockName().typeIn!('one (updated)')
        page.block().find('button', text = 'Save').click!()

        page.blockMenuItem('one (updated)').exists!()

        retry!
          expect([b <- api.blocks, b.name]).to.eql ['one (updated)']
      
      it 'can update a query'
        page.queryMenuItem('one', 'query 1').find('h4').click!()
        page.queryName().typeIn!('query 1 (updated)')
        page.query().find('button', text = 'Overwrite').click!()

        page.queryMenuItem('one', 'query 1 (updated)').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 1 (updated)']
      
      it 'can add a response to a query'
        page.queryMenuItem('one', 'query 1').find('h4').click!()
        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.selectedResponse()
        newResponse.responseSelector().typeIn!('response 2')
        page.query().find('button', text = 'Overwrite').click!()

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
        page.queryMenuItem('one', 'query 1').find('h4').click!()
        page.queryName().typeIn!('query 2 (before 1)')
        page.query().find('button', text = 'Insert Before').click!()

        page.queryMenuItem('one', 'query 2 (before 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 2 (before 1)', 'query 1']
      
      it 'can insert a query after'
        page.queryMenuItem('one', 'query 1').find('h4').click!()
        page.queryName().typeIn!('query 2 (after 1)')
        page.query().find('button', text = 'Insert After').click!()

        page.queryMenuItem('one', 'query 2 (after 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 1', 'query 2 (after 1)']
      
      it 'can delete a query'
        page.queryMenuItem('one', 'query 1').find('h4').click!()
        page.query().find('button', text = 'Delete').click!()

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
        page.queryMenuItem('one', 'query 1').find('h4').click()!
        page.find('button', text = 'Add to Clipboard').click()!

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
          page.queryMenuItem('one', 'query 1').find('h4').click()!

          page.queryName().shouldHave!(value: 'query 1')

          page.clipboardHeader().click()!
          page.clipboardItem('query 2').click()!

          page.queryName().shouldHave!(value: 'query 2')

          page.query().find('li.level input').shouldHave!(value: '1')

          page.query().find('button', text = 'Overwrite').click!()
          page.queryMenuItem('one', 'query 2').exists!()

        it 'can delete the clipboard query'
          page.clipboardHeader().click()!
          page.clipboardItem().shouldHave!(text: ['query 2', 'query 3'])
          page.clipboardItem('query 2').removeButton().click()!
          page.clipboardItem().shouldHave!(text: ['query 3'])
