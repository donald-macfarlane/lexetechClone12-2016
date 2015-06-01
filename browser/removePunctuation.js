module.exports = function(html) {
  return html.replace(/^(&nbsp;|\s)*((<[-a-z0-9_:/]+>(&nbsp;|\s)*)+)?(&nbsp;|\s)*[.,](&nbsp;|\s)*/i, function (_, _2, tag) { return tag || ''; });
};
