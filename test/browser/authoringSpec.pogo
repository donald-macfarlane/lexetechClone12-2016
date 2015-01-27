retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
sendkeys = require './sendkeys'
sendclick = require './sendclick'
$ = require 'jquery'
expect = require 'chai'.expect
chinchilla = require 'chinchilla'

queryApi = require './queryApi'

describe 'authoring'
  div = nil
  api = nil

  find(css, text = nil) =
    retry!
      cssContains =
        if (text)
          css + ":contains(#(JSON.stringify(text)))"
        else
          css

      els = $(div).find(cssContains)
      expect(els.length).to.eql 1 "expected to find exactly one element `#(cssContains)'"
      els.(els.length - 1)

  click(css, text = nil) =
    el = find!(css, text = text)

    //$(el).click()
    sendclick(el)

  typeIn(css, text) =
    el = find!(css)
    sendkeys(el, text)

  context 'when already have a block'
    beforeEach
      div := createTestDiv()
      api := queryApi()

      window.location = '#/authoring/blocks/1/queries/create'

      api.blocks.push {
        name = 'one'
      }

      lexeme(div, {}, { user = { email = 'blah@example.com'} }, { historyApi = false })

    it "asdflk" =>
      self.timeout 100000
      // click!('button', text = 'Add Query')

      typeIn!('.edit-query ul li.name input', 'Query Name')
      click!('.edit-query button', text = 'Create')

      retry!
        expect(api.blocks.(0).queries).to.eql [
          {
            id = "1"
            name = 'Query Name'
            level = 0
            predicants = []
            responses = []
          }
        ]

  context 'when authoring'
    beforeEach
      div := createTestDiv()
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

      lexeme(div, {}, { user = { email = 'blah@example.com'} }, { historyApi = false })

    describe 'blocks'
      beforeEach
        click!('a', text = 'New Block')
        typeIn!('#block_name', 'abcd')
        click!('button', text = 'Create')!

      it.only 'can create a new block'
        retry!
          expect(api.blocks).to.eql [
            {
              id = '1'
              name = 'abcd'
            }
          ]
      
      it 'can create a new query'
        click!('button', text = 'Close')

        click!('a', text = 'New Block')
        typeIn!('#block_name', 'xyz')
        click!('button', text = 'Create')!

        click!('button', text = 'Add Query')

        typeIn!('.edit-query ul li.name input', 'query 1')
        typeIn!('.edit-query ul li.question textarea', 'question 1')
        typeIn!('.edit-query ul li.level input', '3')
        typeIn!('.edit-query ul li div.predicants input', 'hemo viii')
        click!('.edit-query ul li div.predicants ol li', text = 'HemophilVIII')

        click!('.edit-query ul li.responses button', text = 'Add Response')
        typeIn!('.edit-query ul li.responses ul li.selector textarea', 'response 1')
        typeIn!('.edit-query ul li.responses ul li.set-level input', '4')
        typeIn!('.edit-query ul li.responses ul li div.predicants input', 'hemo')
        click!('.edit-query ul li.responses ul li div.predicants ol li', text = 'Hemophilia')
        typeIn!('.edit-query ul li.responses ul li.style1 textarea', 'style 1')
        typeIn!('.edit-query ul li.responses ul li.style2 textarea', 'style 2')

        click!('.edit-query ul li.responses ul li.actions button', text = 'Add Action')
        click!('.edit-query ul li.responses ul li.actions ul.dropdown-menu li a', text = 'Set Block')
        click!('.edit-query ul li.responses ul li.actions ol li.action-set-blocks .select-list ol li', text = 'abcd')

        click!('.edit-query ul li.responses ul li.actions button', text = 'Add Action')
        click!('.edit-query ul li.responses ul li.actions ul.dropdown-menu li a', text = 'Add Block')
        click!('.edit-query ul li.responses ul li.actions ol li.action-add-blocks .select-list ol li', text = 'xyz')

        click!('.edit-query button', text = 'Create')

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
                    style1 = 'style 1'
                    style2 = 'style 2'
                  }
                  actions = [
                    {
                      name = 'setBlocks'
                      arguments = ['1']
                    }
                    {
                      name = 'addBlocks'
                      arguments = ['2']
                    }
                  ]
                  id = 1
                  setLevel = 4
                }
              ]
            }
          ]
        
      it 'can navigate blocks and queries in a tree view'
        api.blocks.push {
          id = '1'
          name = 'one'

          queries = [
            {
              name = 'query 1.1'
              level = 1
            }
            {
              name = 'query 1.2'
              level = 1
            }
            {
              name = 'query 1.3'
              level = 2
            }
          ]
        }
        api.blocks.push {
          id = '2'
          name = 'two'

          queries = [
            {
              name = 'query 2.1'
              level = 1
            }
            {
              name = 'query 2.2'
              level = 1
            }
            {
              name = 'query 2.3'
              level = 2
            }
          ]
        }
