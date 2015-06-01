module.exports = function(html) {
  return html.replace(/^\s*((<[-a-z0-9_:]+>\s*)+)?\s*[.,]\s*/i, function (_, tag) { return tag || ''; });
};
