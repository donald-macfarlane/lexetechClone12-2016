retry = require 'trytryagain'
lexeme = require '../../app/lexeme'
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
                nextQueries = [2]
              }
            ]
          }
          "2" = {
            text = "Is it bleeding?"
            responses = [
              {
                id = 1
                text = 'yes'
                nextQueries = [3]
              }
              {
                id = 2
                text = 'no'
                nextQueries = [3]
              }
            ]
          }
        }
      }
    }

    lexeme(div, graphApi)
    retry!
      expect($('.query .text').text()).to.eql 'Where does it hurt?'

    leftLeg = singleElement! '.query .response:contains("left leg")'
    leftLeg.click()

    retry!
      expect($('.query .text').text()).to.eql 'Is it bleeding?'
