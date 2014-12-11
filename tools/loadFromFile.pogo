loadQueriesFromSql = require './loadQueriesFromSql'
httpism = require 'httpism'

connectionInfoLive = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexemeLive'
}

fs = require 'fs-promise'
queries = JSON.parse(fs.readFile (process.argv.2, 'utf-8')!)

body = httpism.post 'http://localhost:8000/api/queries' (queries)!.body
console.log(body)
