loadQueriesFromSql = require './loadQueriesFromSql'
httpism = require 'httpism'

connectionInfoLive = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexemeLive'
}

body = httpism.post 'http://localhost:8000/queries' (loadQueriesFromSql(connectionInfoLive)!)!.body
console.log(body)
