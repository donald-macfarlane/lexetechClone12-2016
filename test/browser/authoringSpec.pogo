retry = require 'trytryagain'
$ = require '../../browser/jquery'
chai = require 'chai'
expect = chai.expect
browser = require 'browser-monkey'
ckeditorMonkey = require './ckeditorMonkey'
authoringComponent = require '../../browser/routes/authoring/blocks/block'
mountApp = require './mountApp'
predicantLexicon = require '../predicantLexicon'
lexiconBuilder = require '../lexiconBuilder'
hobostyle = require 'hobostyle'
createSnapshots = require './snapshots'
createRouter = require 'mockjax-router'
queryApi = require './queryApi'
karmaDebug = require './karmaDebug'

testBrowser = browser.component(ckeditorMonkey)

if (karmaDebug)
  console.log 'doing snapshots'
  snapshots = createSnapshots()
  testBrowser := testBrowser.on @(evt)
    testDiv = document.querySelector 'body > div.test'
    snapshots.add(testDiv)

authoringElement = testBrowser.component {
  dropdownMenu(name) =
    self.find('.btn-group').containing('button.dropdown-toggle', text = name)

  clipboard() =
    self.find('.clipboard').component {
      clipboardItem(name) = self.find('.menu .item', text = name).component(clipboardItem)
    }

  clipboardTab() =
    self.find('.tabular a', text = 'CLIPBOARD')

  blocksTab() =
    self.find('.tabular a', text = 'BLOCKS')
    
  predicantsTab() =
    self.find('.tabular a', text = 'PREDICANTS')

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
    self.find('.button', text = 'ADD BLOCK')

  closeBlockButton() =
    self.find('button', text = 'Close')

  editQuery() =
    self.find('.edit-query').component(editQueryComponent)

  responses() =
    responsesElement.scope(self.editQuery().find('.field.responses'))

  predicantsEditor() = self.find('.selected-predicant').component(predicantsEditorComponent)
  predicantsMenu() = self.find('.predicant-search').component(predicantsMenuComponent)
}

predicantsMenuComponent = {
  createButton() = self.find('.button', text = 'CREATE')
  search() = self.find('input.search')
  searchResults() = self.find('.results')
  searchResult(name) = self.find('.results a', text = name)
}

predicantsEditorComponent = {
  name() = self.find('input.name')
  saveButton() = self.find('button.save')
  createButton() = self.find('button.create')
  queries() = self.find('.predicant-usages-queries .results > .item')
  responses() = self.find('.predicant-usages-responses .results > .item')
}

blockMenuItemMonkey = testBrowser.component {
  link() = self.find('> .header a')
  expand() = self.find('> .header .icon.right')
  collapse() = self.find('> .header .icon.down')
}

editQueryComponent = {
  name() = self.find('.field.name input')
  insertBeforeButton() = self.find('button', text = 'INSERT BEFORE')
  insertAfterButton() = self.find('button', text = 'INSERT AFTER')
  text() = self.find('.field.question textarea')
  level() = self.find('.field.level input')
  predicants() = self.find('.predicants').component(predicantsMonkey)
  addToClipboardButton() = self.find('button', text = 'ADD TO CLIPBOARD')
  overwriteButton() = self.find('button', text = 'OVERWRITE')
  createButton() = self.find('button', text = 'CREATE')
  deleteButton() = self.find('button', text = 'DELETE')
}

predicantsMonkey = {
  search() = self.find('input')
  result(name) = self.find('.menu .item', text = name)
}

clipboardItem = {
  removeButton() = self.find('.remove')
}

responsesElement = testBrowser.component {
  addResponseButton() = self.find('button', text = 'ADD RESPONSE')
  selectedResponse() = responseElement.scope(self.find('.selected-response'))
}

responseElement = testBrowser.component {
  responseSelector() = self.find('.field.selector input')
  setLevel() = self.find('.field.set-level input')
  predicantSearch() = self.find('.field div.predicants input')
  predicant(name) = self.find('.field div.predicants .menu .item', text = name)
  style1() = self.find('.field.style1 .editor')
  style2() = self.find('.field.style2 .editor')
  actions() = actionsElement.scope(self.find('.field.actions'))
}

actionsElement = testBrowser.component {
  action(name) = self.find('.dropdown .menu .item', text = name)
  addActionButton() = self.find('.button', text = 'ADD ACTION')
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

    startApp(href = '/authoring') =
      mountApp(authoringComponent(), href = href)

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
          blocks = [b <- api.blocks, { id = b.id, name = b.name }]
          expect(blocks).to.eql [
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

        page.blockName().shouldHave(exactValue = '')!

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
        actions.find('.menu .item.action-set-blocks .select-list .menu .item', text = 'abcd').click!()

        page.editQuery().createButton().click!()

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

        page.blockMenuItem('xyz').expand().click()!
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

        page.editQuery().createButton().click!()

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

      it 'trims nbsps from styles'
        responses = page.responses()
        newResponse = responses.selectedResponse()
        newResponse.style1().typeInCkEditorHtml!('one two<br>&nbsp;')
        page.editQuery().createButton().click!()

        retry!
          expect(api.lexicon().blocks.0.queries.0.responses.0.styles.style1).to.eql "one two<br />\n"

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
                {
                  id = '3'
                  name = 'query 3'
                  text = 'question 3'
                  level = 2
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
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().shouldHave!(value = 'query 1')

        page.blockMenuItem('two').expand().click!()
        page.queryMenuItem('two', 'query 2').link().click!()
        page.editQuery().name().shouldHave!(value = 'query 2')

      it 'can collapse and expand a block'
        page.queryMenuItem('one', 'query 1').shouldNotExist!()
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').shouldExist!()
        page.blockMenuItem('one').collapse().click!()
        page.queryMenuItem('one', 'query 1').shouldNotExist!()

      it 'can collapse and expand a query'
        page.blockMenuItem('two').expand().click!()
        page.queryMenuItem('two', 'query 3').shouldExist!()
        page.queryMenuItem('two', 'query 2').collapse().click!()
        page.queryMenuItem('two', 'query 3').shouldNotExist!()
        page.queryMenuItem('two', 'query 2').expand().click!()
        page.queryMenuItem('two', 'query 3').shouldExist!()

    context 'when there are lots of blocks and queries'
      blocks = [
        b <- [1..60]

        {
          id = String(b)
          name "block #(b)"

          queries = [
            q <- [1..30]

            {
              id = String(q)
              name = "query #(q)"
              text = "question #(q)"
              level = 1
              predicants = []
              responses = []
            }
          ]
        }
      ]

      style = nil

      beforeEach
        api.setLexicon({blocks = blocks})
        style := hobostyle.style '.block-query-menu { max-height: 600px !important; }'

      afterEach
        style.remove()

      it 'shows the selected query on navigation'
        block = blocks.25
        query = blocks.25.queries.11
        startApp(href: "/authoring/blocks/#(block.id)/queries/#(query.id)")
        page.queryMenuItem('block 26', 'query 12').shouldExist!()
        page.editQuery().name().shouldHave(value: 'query 12')!
        page.queryMenuItem('block 25', 'query 12').shouldNotExist!()

        page.find('.block-query-menu').shouldHaveElement! @(menu)
          menuTop = $(menu).offset().top

          menuItem = page.queryMenuItem('block 26', 'query 12').link().element()!
          menuItemTop = $(menuItem).offset().top

          expect(menuItemTop - menuTop).to.be.within(30, 80)

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
        page.blockMenuItem('one').link().click!()
        page.blockName().typeIn!('one (updated)')
        page.block().find('button', text = 'Save').click!()

        page.blockMenuItem('one (updated)').exists!()

        retry!
          expect([b <- api.blocks, b.name]).to.eql ['one (updated)']
      
      it 'can update a query'
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().typeIn!('query 1 (updated)')
        page.editQuery().overwriteButton().click!()

        page.queryMenuItem('one', 'query 1 (updated)').exists!()

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 1 (updated)']
      
      it 'can add a response to a query'
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').link().click!()
        responses = page.responses()
        responses.addResponseButton().click!()
        newResponse = responses.selectedResponse()
        newResponse.responseSelector().typeIn!('response 2')
        page.editQuery().overwriteButton().click!()

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
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().typeIn!('query 2 (before 1)')
        page.editQuery().insertBeforeButton().click!()

        page.queryMenuItem('one', 'query 2 (before 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()
        page.editQuery().name().shouldHave!(value: 'query 2 (before 1)')

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 2 (before 1)', 'query 1']
      
      it 'can insert a query after'
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().name().typeIn!('query 2 (after 1)')
        page.editQuery().insertAfterButton().click!()

        page.queryMenuItem('one', 'query 2 (after 1)').exists!()
        page.queryMenuItem('one', 'query 1').exists!()
        page.editQuery().name().shouldHave!(value: 'query 2 (after 1)')

        retry!
          expect([q <- api.lexicon().blocks.0.queries, q.name]).to.eql ['query 1', 'query 2 (after 1)']
      
      it 'can delete a query'
        page.blockMenuItem('one').expand().click!()
        page.queryMenuItem('one', 'query 1').link().click!()
        page.editQuery().deleteButton().click!()

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
        page.blockMenuItem('one').expand().click!()
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

        page.clipboardTab().click()!
        page.clipboard().clipboardItem('query 1').exists()!

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
          page.blockMenuItem('one').expand().click!()
          page.queryMenuItem('one', 'query 1').link().click()!

          page.editQuery().name().shouldHave!(value: 'query 1')

          page.clipboardTab().click()!
          page.clipboard().clipboardItem('query 2').click()!

          page.editQuery().name().shouldHave!(value: 'query 2')
          page.editQuery().level().shouldHave!(value: '1')

          page.editQuery().overwriteButton().click!()
          page.blocksTab().click()!
          page.queryMenuItem('one', 'query 2').exists!()

        it 'can delete the clipboard query'
          page.clipboardTab().click()!
          page.clipboard().clipboardItem().shouldHave!(text: ['query 2', 'query 3'])
          page.clipboard().clipboardItem('query 2').removeButton().click()!
          page.clipboard().clipboardItem().shouldHave!(text: ['query 3'])

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

          startApp()

        it 'can show and search predicants'
          page.predicantsTab().click()!
          predicantsMenu = page.predicantsMenu()
          predicantsMenu.searchResult().shouldHave(text = ['HemophilVIII', 'Hemophilia'])!
          predicantsMenu.search().typeIn('viii')!
          predicantsMenu.searchResult().shouldHave(text = ['HemophilVIII'])!

        it 'can edit and save a predicant'
          page.predicantsTab().click()!
          predicantsMenu = page.predicantsMenu()
          predicantsMenu.searchResult('HemophilVIII').click()!
          predicantsMenu.searchResult('HemophilVIII').shouldHave(css: '.active')!
          page.predicantsEditor().name().shouldHave(value = 'HemophilVIII')!
          page.predicantsEditor().name().typeIn('HemophilVIII (updated)')!
          page.predicantsEditor().saveButton().click()!

          predicantsMenu.searchResult().shouldHave(text = ['HemophilVIII (updated)', 'Hemophilia'])!

          retry!
            expect [p <- api.predicants, p.name].to.eql ['HemophilVIII (updated)', 'Hemophilia']

        it 'can create a predicant'
          page.predicantsTab().click()!
          predicantsMenu = page.predicantsMenu()
          predicantsMenu.createButton().click()!
          predicantsEditor = page.predicantsEditor()
          page.predicantsEditor().name().typeIn('My New Predicant')!
          page.predicantsEditor().createButton().click()!

          predicantsMenu.searchResult().shouldHave(text = ['HemophilVIII', 'Hemophilia', 'My New Predicant'])!

          retry!
            expect [p <- api.predicants, p.name].to.eql ['HemophilVIII', 'Hemophilia', 'My New Predicant']

        it 'predicants show links to queries and responses that contain it'
          page.predicantsTab().click()!
          predicantsMenu = page.predicantsMenu()
          predicantsEditor = page.predicantsEditor()
          predicantsMenu.searchResult('HemophilVIII').click()!
          predicantsEditor.responses().shouldHave(text = ['query1'])!

          predicantsMenu.searchResult('Hemophilia').click()!
          predicantsEditor.queries().shouldHave(text = ['query2'])!

      context 'with predicants'
        beforeEach
          lexicon = lexiconBuilder()

          api.predicants.splice(0, api.predicants.length)

          pred1 = {
            id = '1'
            name = 'bbbb'
          }
          pred2 = {
            id = '2'
            name = 'cccc'
          }
          pred3 = {
            id = '3'
            name = 'aaaa'
          }

          api.predicants.push (pred1, pred2, pred3)

          startApp()

        it 'shows predicants in alpha order'
          page.predicantsTab().click()!
          predicantsMenu = page.predicantsMenu()
          predicantsMenu.searchResult().shouldHave(text = ['aaaa', 'bbbb', 'cccc'])!
