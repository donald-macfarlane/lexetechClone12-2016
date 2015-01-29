lexeme = require './lexeme'
buildGraph = require './buildGraph'

element = document.createElement 'div'
document.body.appendChild(element)
lexeme(element, buildGraph(), window.lexemeData)
