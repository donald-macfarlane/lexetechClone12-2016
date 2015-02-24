require('pogo');
var app = require("./app");
var express = require("express");
var morgan = require("morgan");
var apiUsers = require("./apiUsers.json");
var httpism = require("httpism");
var server = express();

server.use(morgan("combined"));
server.use(app);
server.set("apiUsers", apiUsers);

function githubBackupHttpism() {
  var token, owner, repo;
  token = process.env.BACKUP_GITHUB_TOKEN;
  owner = process.env.BACKUP_GITHUB_REPO_OWNER;
  repo = process.env.BACKUP_GITHUB_REPO;

  if (token && owner && repo) {
    return httpism.api({
      headers: {
        authorization: "token " + token,
        "user-agent": "httpism"
      }
    }, "https://api.github.com/repos/" + owner + "/" + repo + "/contents/");
  }
}

server.set("backupDelay", 1000);
server.set("backupHttpism", githubBackupHttpism());

var port = process.env.PORT || 8000;

server.listen(port, function () {
  console.log("http://localhost:" + port + "/");
});
