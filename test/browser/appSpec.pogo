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

  it 'can generate notes by answering queries'
    div = document.createElement('div')
    div.className = 'test'
    document.body.appendChild(div)

    queryGraph = {
      firstQueryGraph()! = {
        query = {
          text = 'Where does it hurt?'
        }

        responses = [
          {
            response = {
              id = 1
              text = 'left leg'
              notes = 'Complaint
                       ---------
                       left leg'
            }

            query()! = {
              query = {
                text = "Is it bleeding?"
              }

              responses = [
                {
                  response = {
                    id = 1
                    text = 'yes'
                    notes = 'bleeding'
                  }

                  query()! = {
                    query = {
                      text = "Is it aching?"
                    }
                    responses = [
                      {
                        response = {
                          id = 1
                          text = 'yes'
                        }
                        query() = nil
                      }
                      {
                        response = {
                          id = 2
                          text = 'no'
                        }
                        query() = nil
                      }
                    ]
                  }
                }
                {
                  response = {
                    id = 2
                    text = 'no'
                  }

                  query()! = {
                    query = {
                      text = "Is it aching?"
                    }
                    responses = [
                      {
                        response = {
                          id = 1
                          text = 'yes'
                        }
                        query() = nil
                      }
                      {
                        response = {
                          id = 2
                          text = 'no'
                        }
                        query() = nil
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }

    lexeme(div, queryGraph, {user = { email = 'blah@example.com'}})

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
