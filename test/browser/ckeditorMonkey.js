module.exports = {
  typeInCkEditorHtml: function (html) {
    return this.is('.cke_editable').element().then(function (editorElement) {
      var editor = Object.keys(CKEDITOR.instances).map(function (key) {
        return CKEDITOR.instances[key];
      }).filter(function (instance) {
        return instance.element.$ == editorElement;
      })[0];

      return new Promise(function (fulfil) {
        editor.setData(html, fulfil);
      });
    });
  }
};
