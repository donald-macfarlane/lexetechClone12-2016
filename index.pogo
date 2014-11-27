orderedLexemes = require './orderedLexemes'
buildGraph = require './buildGraph'
dotGraph = require './dotGraph'

lexemes = orderedLexemes()!

printLexemes() =
  debug('lexemes', lexemes)

// printLexemes()

console.log "digraph g {"
buildGraph(lexemes, dotGraph())
console.log "}"
