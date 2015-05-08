shell = require './tools/ps'
loadQueriesFromSql = require './tools/loadQueriesFromSql'
fs = require 'fs-promise'
httpism = require 'httpism'

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

envs = {
  prod = 'http://api:squidandeels@lexetech.herokuapp.com/api/lexicon'
  dev = 'http://api:squidandeels@localhost:8000/api/lexicon'
}

task 'load-from-file' @(args, env = 'dev')
  file = args.0

  queries = JSON.parse(fs.readFile (file, 'utf-8')!)

  url = envs.(env)
  body = httpism.post (url, queries)!.body
  console.log(body)

task 'download-lexicon' @(args, env = 'dev')
  url = envs.(env)
  body = httpism.get (url)!.body
  console.log(JSON.stringify(body, null, 2))

task 'sqldump' @(args, env = 'local.json')
  creds = JSON.parse(fs.readFile(env, 'utf-8')!)
  console.log(JSON.stringify(loadQueriesFromSql(creds)!, nil, 2))

compileLess() =
  recess = require 'recess'
  try
    data = recess './browser/style/app.less' { compile = true } ^!
    console.log("Less compiled")
    fs.writeFile('./server/generated/app.css')!
  catch (e)
    console.log("Less errors", e)

task 'css'
  compileLess()!

task 'watch-css'
  compileLess()!
  require 'fs'.watch './browser/style'
    compileLess()!
