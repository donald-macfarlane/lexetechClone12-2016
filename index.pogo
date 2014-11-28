orderedLexemes = require './orderedLexemes'
buildGraph = require './buildGraph'
dotGraph = require './dotGraph'

lexemes = orderedLexemes()!

printLexemes() =
  debug('lexemes', lexemes)

// printLexemes()

time(block) =
  startTime = new (Date ()).getTime()
  block()
  endTime = new (Date ()).getTime()
  console.log "/* took #(endTime - startTime) */"

time
  console.log "digraph g {"
  buildGraph(lexemes, dotGraph(stdout = true), maxDepth = 15)
  console.log "}"
