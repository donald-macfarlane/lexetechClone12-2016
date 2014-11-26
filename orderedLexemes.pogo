sworm = require 'sworm'
_ = require 'underscore'

group (items) by (fn) map (map) =
  groups = _.groupBy (items, fn)
  [k <- Object.keys(groups), map(groups.(k))]

module.exports() =
  db = sworm.db! {
    driver = 'mssql'
    config = {
      user = 'lexeme'
      password = 'password'
      server = 'windows'
      database = 'dbLexeme'
    }
  }

  try
    mains = db.query! 'select *
                       from tblMain main
                         join tblModifier modifier
                           on main.MainID = modifier.MainID'

    unsortedQueries = group (mains) by @(m) @{
      m.MainID.0
    } map @(ms) @{
      main = ms.0
      {
        name = main.NavigantInfo
        navMajor = main.NavMajor
        navMinor = main.NavMinor
        level = main.Level
        block = main.BlockID
        query = main.QText
        responses = [
          m <- ms
          {
            response = m.Mod
            setLevel = m.LevelSet
            text = {"one" = m.StyleOne}
            action = m.Action
            actionDetails = m.ActionDetails
          }
        ]
      }
    }

    unsortedQueries.sort @(left, right)
      major = compare(left.navMajor, right.navMajor)
      if (major == 0)
        compare(left.navMinor, right.navMinor)
      else
        major
  finally
    db.close()!

compare(a, b) =
  if (a > b)
    1
  else if (a < b)
    -1
  else
    0