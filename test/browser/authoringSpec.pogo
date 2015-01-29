retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
createTestDiv = require './createTestDiv'
sendkeys = require './sendkeys'
sendclick = require './sendclick'
$ = require 'jquery'
expect = require 'chai'.expect
chinchilla = require 'chinchilla'

createRouter = require './router'

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
        click!('button', text = 'Add Block')
        typeIn!('#block_name', 'abcd')
        click!('button', text = 'Create')!

      it 'can create a new block'
        retry!
          expect(api.blocks).to.eql [
            {
              id = '1'
              name = 'abcd'
            }
          ]

        find('.blocks-queries ol li:contains("1: abcd")')!

        retry!
          expect($(div).find('#block_name').val()).to.equal('abcd')
      
      it 'can create a new query'
        find('button', text = 'Close')!
        click!('button', text = 'Add Block')

        retry!
          expect($(find('#block_name')!).val()).to.equal ''

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

        retry!
          block = $(div).find('.blocks-queries ol li:contains("2: xyz")')
          query = block.find('ol li:contains("query 1")')
          expect(query.length).to.equal(1)

    describe 'clipboards'
      it.only 'can add a query to the clipboard'
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

        query = retry!
          block = $(div).find('.blocks-queries ol li:contains("1: one")')
          q = block.find('ol li:contains("query 1")')
          expect(q.length).to.equal(1)
          q

        click!(query)
        click!('button', text = 'Add to Clipboard')

        retry!
          expect([q <- api.userQueries, q.name]).to.eql ['query 1']

        click('button.clipboard', text = 'Clipboard')
