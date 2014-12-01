retry = require 'trytryagain'
lexeme = require '../../browser/lexeme'
removeTestElement = require './removeTestElement'
$ = require 'jquery'
expect = require 'chai'.expect

describe 'lexeme'
  beforeEach
    removeTestElement()

  singleElement(css) =
    retry!
      e = $(css)
      expect(e.length).to.eql 1
      e

  shouldHaveQuery(query) =
    retry!
      expect($('.query .text').text()).to.eql (query)

  shouldBeFinished() =
    retry!
      expect($('.finished').length).to.eql 1

  selectResponse(response) =
    responseElement = singleElement! ".query .response:contains(#(JSON.stringify(response)))"
    responseElement.click()

  notesShouldBe(notes) =
    retry!
      expect($'.notes'.text()).to.eql (notes)

  it 'can answer a query and ask the next query'
    div = document.createElement('div')
    div.className = 'test'
    document.body.appendChild(div)

    graphApi = {
      graphForQuery(query)! = {
        firstQuery = "1"
        queries = {
          "1" = {
            text = 'Where does it hurt?'

            responses = [
              {
                id = 1
                text = 'left leg'
                nextQuery = 2
                notes = 'Complaint
                         ---------
                         left leg'
              }
            ]
          }
          "2" = {
            text = "Is it bleeding?"
            responses = [
              {
                id = 1
                text = 'yes'
                nextQuery = 3
                notes = 'bleeding'
              }
              {
                id = 2
                text = 'no'
                nextQuery = 3
              }
            ]
          }
          "3" = {
            text = "Is it aching?"
            responses = [
              {
                id = 1
                text = 'yes'
              }
              {
                id = 2
                text = 'no'
              }
            ]
          }
        }
      }
    }

    lexeme(div, graphApi)

    shouldHaveQuery 'Where does it hurt?'!
    selectResponse 'left leg'!
    shouldHaveQuery 'Is it bleeding?'!
    selectResponse 'yes'!
    shouldHaveQuery 'Is it aching?'!
    selectResponse 'no'!
    shouldBeFinished()!

    notesShouldBe! "Complaint
                    ---------
                    left leg bleeding"
