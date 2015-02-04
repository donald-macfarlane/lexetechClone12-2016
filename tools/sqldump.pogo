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

connectionInfoLatest = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexeme_2015_2_4'
}

console.log(JSON.stringify(loadQueriesFromSql(connectionInfoLatest)!, nil, 2))
