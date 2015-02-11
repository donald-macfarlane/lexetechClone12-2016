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

connectionInfoLatest10 = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexeme_2015_2_10'
}

console.log(JSON.stringify(loadQueriesFromSql(connectionInfoLatest10)!, nil, 2))
