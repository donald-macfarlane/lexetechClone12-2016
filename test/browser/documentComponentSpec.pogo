mountApp = require './mountApp'
expect = require 'chai'.expect
browser = require 'browser-monkey'
queryApi = require './queryApi'
retry = require 'trytryagain'
documentComponent = require '../../browser/documentComponent'
createDocument = require '../../browser/document'
createHistory = require '../../browser/history'

documentBrowser = browser.component {
  document() = self.find('.document')
}

describe 'document component'
  beforeEach =>
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
    documentBrowser.document().shouldHave! { text 'onetwo' }

  describe 'punctuation suppression'
    it 'supresses punctuation between lexemes that have style'
      withLexemes [
        {
          query = { id = '1' }
          suppressPunctuation = true
          response = { styles = { style1 = '<p>one</p>' } }
        }
        {
          query = { id = '1' }
          response = { styles = { style1 = '<p>&nbsp; &nbsp;</p>' } }
        }
        {
          query = { id = '1' }
          response = { styles = { style1 = '<p>, two</p>' } }
        }
      ]
      documentBrowser.document().shouldHave! { text = 'onetwo' }

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
      documentBrowser.document().shouldHave! { text = 'text lower, more text upper'}
