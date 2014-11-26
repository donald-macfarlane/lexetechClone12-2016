orderedLexemes = require './orderedLexemes'

lexemes = orderedLexemes()!

clone(o) =
  JSON.parse(JSON.stringify(o))

actions = {
  none (context) = nil
  email (context) = nil

  addBlocks (context, blocks, ...) =
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setBlocks (context, blocks, ...) =
    context.blocks = {}
    for each @(block) in (blocks)
      context.blocks.(block) = true

  setVariable (context, variable, value) = nil

  repeatLexeme (context) =
    --context.coherenceIndex

  loopBack (context) = nil
}

buildGraph(lexemes) =
  exploredQueries = {}

  findNextQuery(context) =
    findNextItem @(item) in (lexemes) startingFrom (context.coherenceIndex) matching
      item.level >= context.level

  selectResponse (response) forQuery (query, context) =
    console.log "query_#(query.id) -> response_#(response.id)"
    console.log "response_#(response.id) [label=#(JSON.stringify(response.response))]"

    newContext = clone(context)
    newContext.level = response.setLevel
    ++newContext.coherenceIndex

    action = actions.(response.action.name)
    action(newContext, response.action.arguments, ...)

    console.log "/* coherenceIndex = #(newContext.coherenceIndex) */"

    nextQuery = findNextQuery(newContext)

    if (nextQuery)
      newContext.coherenceIndex = nextQuery.index
      console.log "response_#(response.id) -> query_#(nextQuery.id)"
      buildGraphForQuery(nextQuery, newContext)

  query = lexemes.(0)

  buildGraphForQuery(query, context) =
    if (@not exploredQueries.(query.id))
      exploredQueries.(query.id) = true

      console.log "query_#(query.id) [label=#(JSON.stringify(query.name))]"

      [
        response <- query.responses
        selectResponse (response) forQuery (query, context)
      ]
    else
      nil

  buildGraphForQuery(query) {
    coherenceIndex = 0
    blocks = {}
    level = 1
    predicants = {}
  }

findNextItemIn (array) startingFrom (index) matching (predicate) =
  for (n = index, n < array.length, ++n)
    item = array.(n)
    if (predicate(item))
      item.index = n
      return (item)

console.log "digraph g {"
buildGraph(lexemes)
console.log "}"
