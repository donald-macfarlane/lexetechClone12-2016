loadQueriesFromSql = require './loadQueriesFromSql'
httpism = require 'httpism'

connectionInfoLive = {
  user = 'lexeme'
  password = 'password'
  server = 'windows'
  database = 'dbLexemeLive'
}

fs = require 'fs-promise'

filename = process.argv.3

queries = JSON.parse(fs.readFile (process.argv.2, 'utf-8')!)

envs = {
  prod = 'http://api:squidandeels@lexetech.herokuapp.com/api/queries' 
  dev = 'http://api:squidandeels@localhost:8000/api/queries' 
}

body = httpism.post 'http://api:squidandeels@lexetech.herokuapp.com/api/queries' (queries)!.body
console.log(body)
