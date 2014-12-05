loadQueriesFromSql = require './loadQueriesFromSql'

connectionInfo = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexeme'
}

connectionInfoLive = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexemeLive'
}

console.log(JSON.stringify(loadQueriesFromSql(connectionInfoLive)!, nil, 2))
