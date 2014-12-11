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

task 'test'
  runAllThenThrow! (
    @{ shell 'mocha test/*Spec.* test/server/*Spec.*' }
    @{ shell 'karma start --single-run' }
    @{ shell 'cucumber' }
  )
