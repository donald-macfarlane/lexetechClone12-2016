childProcess = require 'child_process'
shellQuote = require 'shell-quote'
glob = require 'glob'

module.exports = shell (cmd, args, opts) =
  if (@not (args :: Array))
    shell('sh', ['-c', cmd], args)
  else
    args := args @or []
    opts := opts @or {}
    opts.stdio = opts.stdio @or 'inherit'
    p = childProcess.spawn(cmd, args, opts)

    promise! @(result, error)
      p.on 'exit' @(exitCode, signal)
        if (exitCode == 0)
          result()
        else
          error(new (Error "#(shellQuote.quote [cmd, args, ...]), exit code #(exitCode)"))
