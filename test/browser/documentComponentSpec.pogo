mountApp = require './mountApp'
expect = require 'chai'.expect
element = require './element'
queryApi = require './queryApi'
retry = require 'trytryagain'
documentComponent = require '../../browser/documentComponent'
createDocument = require '../../browser/document'
createHistory = require '../../browser/history'

documentBrowser = prototypeExtending(element) {
  document() = self.find('ol.document')
}

describe 'document component'
  browser = nil

  beforeEach =>
    self.timeout 100000
    $.mockjaxSettings.logging = false

  withLexemes(lexemes) =
    document = createDocument {
      lexemes = lexemes
    }
    history = createHistory {
      document = document
    }
    docComponent = documentComponent(history: history)
    component = {
      render() =
        docComponent.render('style1')
    }
    mountApp(component)

    browser := documentBrowser { selector = '.test' }

  it 'displays lexeme styles consecutively'
    withLexemes [
      {
        query = { id = '1' }
        response = { styles = { style1 = 'one' } }
      }
      {
        query = { id = '1' }
        response = { styles = { style1 = 'two' } }
      }
    ]
    browser.document().expect!(element.hasText('onetwo'))

  describe 'punctuation suppression'
    it 'supresses punctuation between lexemes that have style'
      withLexemes [
        {
          query = { id = '1' }
          suppressPunctuation = true
          response = { styles = { style1 = 'one' } }
        }
        {
          query = { id = '1' }
          response = { styles = { style1 = ' ' } }
        }
        {
          query = { id = '1' }
          response = { styles = { style1 = ', two' } }
        }
      ]
      browser.document().expect!(element.hasText('onetwo'))

  describe 'variables'
    it 'substitutes variables, forward and back'
      withLexemes [
        {
          query = { id = '1' }
          variables = [
            { name = 'Var', value = 'upper' }
          ]
          response = { styles = { style1 = 'text !var' } }
        }
        {
          query = { id = '1' }
          variables = [
            { name = 'var', value = 'lower' }
          ]
          response = { styles = { style1 = ', more text !Var' } }
        }
      ]
      browser.document().expect!(element.hasText('text lower, more text upper'))
