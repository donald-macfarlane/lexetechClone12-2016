orderedLexemes = require './orderedLexemes'

lexemes = orderedLexemes()!

buildGraph(lexemes) =
  findNextQuery(coherenceIndex, context) =
    findNextItem @(item) in (lexemes) startingFrom (coherenceIndex) matching
      item.level >= context.level @and context.blocks.(item.block)

  selectResponse (response) forQuery (query, coherenceIndex, context) =
    newContext = context
      0 () = context
      1 () =
        clone(context)

      2 () =
        clone(context)

      3 () =
        clone(context)

      4 () =
        clone(context)

      5 () =
        clone(context)

      8 () =
        clone(context)
    }

    nextQuery = findNextQuery(coherenceIndex + 1, newContext)
    buildGraphForQuery(nextQuery, coherenceIndex + 1, newContext)

  query = lexemes.(0)

  buildGraphForQuery(query, coherenceIndex, context) =
    [
      response <- query.responses
      selectResponse (response) forQuery (query, coherenceIndex, context)
    ]

  buildGraphForQuery(query, 0, {}, 1, {})

findNextItemIn (array) startingFrom (index) matching (predicate) =
  for (n = index, n < array.length, ++n)
    item = array.(n)
    if (predicate(item))
      return (item)

console.log(lexemes)