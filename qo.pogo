shell = require './tools/ps'

runAllThenThrow(args, ...) =
  firstError = nil

  for each @(arg) in (args)
    try
      arg()!
    catch (e)
      firstError := firstError @or e

  if (firstError)
    throw(firstError)

mocha() = shell 'mocha test/*Spec.* test/server/*Spec.*'
karma() = shell 'karma start --single-run'
cucumber() = shell 'cucumber'

task 'test'
  runAllThenThrow! (
    @{ mocha() }
    @{ karma() }
    @{ cucumber() }
  )

task 'mocha'
  mocha()!

task 'cucumber'
  cucumber()!

task 'karma'
  karma()!

task 'load-from-file' @(args, env = 'dev')
  file = args.0

  loadQueriesFromSql = require './tools/loadQueriesFromSql'
  httpism = require 'httpism'

  connectionInfoLive = {
    user = 'lexeme'
    password = 'password'
    server = 'windows'
    database = 'dbLexemeLive'
  }

  fs = require 'fs-promise'

  queries = JSON.parse(fs.readFile (file, 'utf-8')!)

  envs = {
    prod = 'http://api:squidandeels@lexetech.herokuapp.com/api/queries' 
    dev = 'http://api:squidandeels@localhost:8000/api/queries' 
  }

  body = httpism.post (envs.(env)) (queries)!.body
  console.log(body)
