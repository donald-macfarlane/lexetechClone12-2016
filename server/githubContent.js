function decodeBase64(base64) {
  return new Buffer(base64, 'base64').toString('ascii');
}

function encodeBase64(base64) {
  return new Buffer(base64).toString('base64');
}

function GithubContents(api) {
  this.api = api;
}

GithubContents.prototype.get = function(filename) {
  return this.api.get(filename).then(function (response) {
    return decodeBase64(response.body.content);
  });
};

GithubContents.prototype.put = function (filename, content) {
  var self = this;
  return this.api.get('').then(function (response) {
    var file = response.body.filter(function (file) {
      return file.name == filename;
    })[0];

    if (file) {
      return file.sha;
    }
  }).then(function (sha) {
    return self.api.put(filename, {
      message: 'backup lexicon',
      content: encodeBase64(content),
      sha: sha
    });
  });
}

module.exports = function (api) {
  return new GithubContents(api);
};
