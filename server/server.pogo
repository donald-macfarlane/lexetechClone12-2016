app = require './app'
express = require 'express'
morgan = require 'morgan'
apiUsers = require './apiUsers.json'
httpism = require 'httpism'

server = express()
server.use(morgan('combined'))
server.use(app)
server.set('apiUsers', apiUsers)

githubBackupHttpism =
  token = process.env.BACKUP_GITHUB_TOKEN
  owner = process.env.BACKUP_GITHUB_REPO_OWNER
  repo = process.env.BACKUP_GITHUB_REPO

  if (token @and owner @and repo)
    httpism.api(
      {
        headers = {
          authorization = 'token ' + token
          'user-agent' = 'httpism'
        }
      }
      "https://api.github.com/repos/#(owner)/#(repo)/contents/"
    )

server.set('backupDelay', 1000)
server.set('backupHttpism', githubBackupHttpism)

port = process.env.PORT || 8000
server.listen(port, ^)!
console.log "http://localhost:#(port)/"
