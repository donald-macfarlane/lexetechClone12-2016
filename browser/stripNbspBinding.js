module.exports = {
  model: function (view) {
    return view.replace(/<br\s*\/?>\n?&nbsp;$/mi, '<br />\n');
  },

  view: function (model) {
    return model.replace(/<br\s*\/?>\n?$/mi, '<br />\n&nbsp;');
  }
};
