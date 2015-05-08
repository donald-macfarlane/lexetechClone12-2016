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
  prod = 'http://api:squidandeels@lexetech.herokuapp.com/api/'
  dev = 'http://api:squidandeels@localhost:8000/api/'
}

createApi(env) =
  url = envs.(env)
  httpism.api(url)

task 'load-from-file' @(args, env = 'dev')
  file = args.0

  queries = JSON.parse(fs.readFile (file, 'utf-8')!)

  api = createApi(env)
  body = api.post ('lexicon', queries)!.body
  console.log(body)

task 'download-lexicon' @(args, env = 'dev')
  url = envs.(env)
  api = createApi(env)
  body = api.get ('lexicon')!.body
  console.log(JSON.stringify(body, null, 2))

task 'sqldump' @(args, env = 'local.json')
  creds = JSON.parse(fs.readFile(env, 'utf-8')!)
  console.log(JSON.stringify(loadQueriesFromSql(creds)!, nil, 2))

modifyUser(userQuery, modify, env = 'dev') =
  api = createApi(env)
  usersResponse = api.get!('users/search', querystring = {q = userQuery})
  users = usersResponse.body.results

  if (users.length > 1)
    console.log "more than one user found:"
    users.forEach @(user)
      console.log(JSON.stringify(user, nil, 2))
  else
    user = api.get!(users.0.href).body
    modify(user)
    response = api.put!(user.href, user)

    console.log("#(response.statusCode) => #(JSON.stringify(response.body, nil, 2))")

task 'add-admin' @(args, env = 'dev')
  modifyUser(args.0, env = env) @(user)
    user.admin = true

task 'add-author' @(args, env = 'dev')
  modifyUser(args.0, env = env) @(user)
    user.author = true

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
