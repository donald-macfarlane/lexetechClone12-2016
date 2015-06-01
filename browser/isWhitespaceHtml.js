module.exports = function (html) {
  return html.replace(/(\s|<[-a-z0-9_:/]+>|&nbsp;)*/, '') == '';
};
