sworm = require 'sworm'
_ = require 'underscore'
enumerateRange = require './enumerateRange'

group (items) by (fn) map (map) =
  groups = _.groupBy (items, fn)
  _.object [k <- Object.keys(groups), [k, map(groups.(k))]]

module.exports(connectionInfo) =
  db = sworm.db! {
    driver = 'mssql'
    config = connectionInfo
  }

  try
    mains = db.query! 'select *
                       from tblMain main
                         join tblModifier modifier
                           on main.MainID = modifier.MainID
                       where main.MainID not in (929, 910, 913, 912, 896)'

    queriesById = group (mains) by @(m) @{
      m.MainID.0
    } map @(ms) @{
      main = ms.0
      {
        id = String(main.MainID.0)
        name = main.NavigantInfo
        navMajor = main.NavMajor
        navMinor = main.NavMinor
        level = main.Level
        block = main.BlockID
        text = main.QText

        responses = [
          m <- ms

          buildAction = {
            "1" = @()
              {name = 'email', arguments = []}

            "2" = @()
              { name = 'addBlocks', arguments = enumerateRange(m.ActionDetails) }

            "3" = @()
              { name = 'setBlocks', arguments = enumerateRange(m.ActionDetails) }

            "4" = @()
              { name = 'setVariable', arguments = m.ActionDetails.split '|' }

            "5" = @()
              { name = 'repeatLexeme', arguments = [] }

            "8" = @()
              { name = 'loopBack', arguments = [] }
          }.(m.Action) @or @() @{ { name = 'none', arguments = [] } }

          action = buildAction()

          {
            id = String(m.ModID)
            text = m.Mod
            setLevel = m.LevelSet
            styles {
              style1 = m.StyleOne
              style2 = m.StyleTwo
            }
            actions = [action]
          }
        ]
      }
    }

    responsesById = _.object [
      q <- _.values(queriesById)
      r <- q.responses
      [r.id, r]
    ]

    queryPredicants = db.query!  'select MainID,[Set]
                                  from tblSetBy sb
                                    join tlkSets
                                      on sb.IsSetBy = tlkSets.SetID'

    queryPredicantsById = _.groupBy(queryPredicants, 'MainID')

    merge (queriesById, queryPredicantsById) map @(query, predicants)
      query.predicants =
        if (predicants)
          [p <- predicants, p.Set]
        else
          []

    responsePredicants = db.query! 'select ModID,[Set]
                                    from tblSets
                                      join tlkSets
                                        on tblSets.Sets = tlkSets.SetID'

    responsePredicantsById = _.groupBy(responsePredicants, 'ModID')

    merge (responsesById, responsePredicantsById) map @(response, predicants)
      response.predicants =
        if (predicants)
          [p <- predicants, p.Set]
        else
          []

    blocks = _.groupBy(_.values(queriesById), 'block')
    {
      blocks = [
        bkey <- Object.keys(blocks)
        {
          id = String(bkey)
          queries = sortQueriesByCoherenceOrder(blocks.(bkey))
        }
      ]
    }
  finally
    db.close()!

sortQueriesByCoherenceOrder(queries) =
  sortedQueries = queries.sort @(left, right)
    major = compare(left.navMajor, right.navMajor)
    if (major != 0)
      major
    else
      compare(left.navMinor, right.navMinor)

  sortedQueries.forEach @(q)
    delete(q.navMajor)
    delete(q.navMinor)

  sortedQueries


compare(a, b) =
  if (a > b)
    1
  else if (a < b)
    -1
  else
    0

merge (left, right) map (block) =
  [
    lkey <- Object.keys(left)

    r = right.(lkey)
    l = left.(lkey)

    block(l, r)
  ]
