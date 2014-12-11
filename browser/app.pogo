lexeme = require './lexeme'
queryApi = require './queryApi'

element = document.createElement 'div'
document.body.appendChild(element)
lexeme(element, queryApi, window.lexemeData)
