retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
sendkeys = require './sendkeys'
sendclick = require './sendclick'
$ = require 'jquery'
chai = require 'chai'
expect = chai.expect
element = require './element'

createRouter = require 'mockjax-router'

queryApi = require './queryApi'

authoringElement = prototypeExtending (element) {
  dropdownMenu(name) =
    self.find('.btn-group').containing('button.dropdown-toggle', text = name)

  clipboard() =
    self.find('.clipboard')

  clipboardHeader() =
    self.clipboard().find('a', text = 'Clipboard')

  clipboardItem(name) =
    self.clipboard().find('ol li', text = name)
    
  dropdownMenuItem(name) =
    self.find('ul.dropdown-menu li a', text = name)

  queryMenuItem(blockName, queryName) =
    self.blockMenuItem(blockName).find('ol li', text = queryName, message = "query  #(JSON.stringify(queryName))")

  blockMenuItem(blockName, queryName) =
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
    responsesElement(self.query().find('ul li.responses'))
  
  actions() =
    self.responses().find('ul li.actions')

  action(name) =
    self.actions().find('ul.dropdown-menu li a', text = name)
}

responsesElement = prototypeExtending(element) {
  addResponseButton() = self.find('button', text = 'Add Response')
  response(n) = responseElement(self.find("ol li:nth-of-type(#(n))"))
}

responseElement = prototypeExtending(element) {
  selector() = self.find('ul li.selector textarea')
  setLevel() = self.find('ul li.set-level input')
  predicantSearch() = self.find('ul li div.predicants input')
  predicant(name) = self.find('ul li div.predicants ol li', text = 'Hemophilia')
  style1() = self.find('ul li.style1 .editor')
  style2() = self.find('ul li.style2 .editor')
}

describe 'authoring'
  div = nil
  api = nil

  foundElement = prototype {
    click() = sendclick(self.element)
    typeIn(text) = sendkeys(self.element, text)

    find(css, predicate = nil, text = nil, contains = nil) =
      retry!
        cssContains =
          if (text)
            css + ":contains(#(JSON.stringify(text)))"
          else
            css

        els = $(self.element).find(cssContains)
        expect(els.length).to.eql 1 "expected to find exactly one element `#(cssContains)'"
        found = els.(els.length - 1)

        if (predicate)
          predicate(found)

        if (contains)
          expect($(found).find(contains).length).to.be.greaterThan(0)

        foundElement { element = found }
  }

  context 'when authoring'
    page = nil

    beforeEach
      div := createTestDiv()
      page := authoringElement { element = div }

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
        newResponse = responses.response(1)
        newResponse.selector().typeIn!('response 1')
        newResponse.setLevel().typeIn!('4')
        newResponse.predicantSearch().typeIn!('hemo')
        newResponse.predicant('Hemophilia').click!()
        newResponse.style1().typeInHtml!('<p>style 1</p>')
        newResponse.style2().typeInHtml!('<p>style 2</p>')

        actions = responses.find('ul li.actions')
        actions.find('button', text = 'Add Action').click!()
        actions.find('ul.dropdown-menu li a', text = 'Set Blocks').click!()
        actions.find('ol li.action-set-blocks .select-list ol li', text = 'abcd').click!()

        page.find('.edit-query button', text = 'Create').click!()

        retry!
          expect(api.blocks.(1).queries).to.eql [
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
                    style1 = '<p>style 1</p>'
                    style2 = '<p>style 2</p>'
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
            console.log "#(actionName) exists"
            page.action(actionName).exists!()

          page.action(action).click!()

          for each @(actionName) in (disallowedActions)
            console.log "#(actionName) doesn't exist"
            page.action(actionName).doesntExist!()

      describe 'repeat'
        'Repeat' isNotCompatibleWith ['Set Blocks', 'Add Blocks']

      describe 'add blocks'
        'Add Blocks' isNotCompatibleWith ['Set Blocks', 'Add Blocks']

      describe 'set blocks'
        'Set Blocks' isNotCompatibleWith ['Set Blocks', 'Add Blocks']

    describe 'selecting blocks and queries'
      beforeEach
        api.blocks.push {
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
        api.blocks.push {
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

        startApp()

      it 'can select one block after another'
        page.blockMenuItem('one').click!()
        page.blockName().wait! @(element)
          expect(element.val()).to.equal 'one'

        page.blockMenuItem('two').click!()
        page.blockName().wait! @(element)
          expect(element.val()).to.equal 'two'

      it 'can select one query after another'
        page.queryMenuItem('one', 'query 1').click!()
        page.queryName().wait! @(element)
          expect(element.val()).to.equal 'query 1'

        page.queryMenuItem('two', 'query 2').click!()
        page.queryName().wait! @(element)
          expect(element.val()).to.equal 'query 2'

    describe 'updating and inserting queries'
      beforeEach
        api.blocks.push {
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

        startApp()
      
      it 'can update a block'
        page.queryMenuItem('one').click!()
        page.blockName().typeIn!('one (updated)')
        page.block().find('button', text = 'Save').click!()

        page.blockMenuItem('one (updated)').exists!()

        retry!
          expect([b <- api.blocks, b.name]).to.eql ['one (updated)']
      
      it 'can update a query'
        page.queryMenuItem('one', 'query 1').click!()
        page.queryName().typeIn!('query 1 (updated)')
        page.query().find('button', text = 'Overwrite').click!()

        page.queryMenuItem('one', 'query 1 (updated)').exists!()

        retry!
          expect([q <- api.blocks.0.queries, q.name]).to.eql ['query 1 (updated)']
      
      it 'can add a response to a query'
        page.queryMenuItem('one', 'query 1').click!()
        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.response(2)
        newResponse.selector().typeIn!('response 2')
        page.query().find('button', text = 'Overwrite').click!()

        retry!
          actual = [r <- api.blocks.0.queries.0.responses, {id = r.id, text = r.text}]
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
        page.queryMenuItem('one', 'query 1').click!()
        page.queryName().typeIn!('query 2 (before 1)')
        page.query().find('button', text = 'Insert Before').click!()

        page.queryMenuItem('one', 'query 2 (before 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()

        retry!
          expect([q <- api.blocks.0.queries, q.name]).to.eql ['query 2 (before 1)', 'query 1']
      
      it 'can insert a query after'
        page.queryMenuItem('one', 'query 1').click!()
        page.queryName().typeIn!('query 2 (after 1)')
        page.query().find('button', text = 'Insert After').click!()

        page.queryMenuItem('one', 'query 2 (after 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()

        retry!
          expect([q <- api.blocks.0.queries, q.name]).to.eql ['query 1', 'query 2 (after 1)']
      
      it 'can delete a query'
        page.queryMenuItem('one', 'query 1').click!()
        page.query().find('button', text = 'Delete').click!()

        page.queryMenuItem('one', 'query 1').doesntExist!()

        retry!
          expect([q <- api.blocks.0.queries, @not q.deleted, q.name]).to.eql []

    describe 'clipboards'
      beforeEach
        api.blocks.push {
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
        startApp()

      it 'can add a query to the clipboard'
        page.queryMenuItem('one', 'query 1').click()!
        page.find('button', text = 'Add to Clipboard').click()!

        retry!
          expect(api.clipboard).to.eql [
            {
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
          startApp()

        it 'can paste the query into a new query, not including level'
          page.queryMenuItem('one', 'query 1').click()!

          page.queryName().wait! @(input)
            expect(input.val()).to.equal 'query 1'

          page.clipboardHeader().click()!
          page.clipboardItem('query 2').click()!

          page.queryName().wait! @(input)
            expect(input.val()).to.equal 'query 2'

          page.query().find('li.level input').wait! @(input)
            expect(input.val()).to.equal '1'

          page.query().find('button', text = 'Overwrite').click!()
          page.queryMenuItem('one', 'query 2').exists!()
