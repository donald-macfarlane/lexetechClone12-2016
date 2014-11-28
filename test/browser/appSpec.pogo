retry = require 'trytryagain'
lexeme = require '../../app/lexeme'
removeTestElement = require './removeTestElement'
$ = require 'jquery'
expect = require 'chai'.expect

describe 'lexeme'
  beforeEach
    removeTestElement()

  it 'renders something'
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
                text = 'left leg'
                next_query = [2]
              }
            ]
          }
          "2" = {
            text 'next query'
            responses = []
          }
        }
      }
    }

    lexeme(div, graphApi)
    retry!
      expect($('.query .text').text()).to.eql 'where does it hurt?'
