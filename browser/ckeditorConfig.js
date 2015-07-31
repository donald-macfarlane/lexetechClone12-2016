module.exports = {
  enterMode: CKEDITOR.ENTER_BR,
  extraPlugins: 'sourcedialog',
  toolbarGroups: [
    { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
    { name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align' ] },
    { name: 'styles' },
    { name: 'document',    groups: [ 'mode', 'document', 'doctools' ] }
  ],
  format_tags : 'p;h1;h2;h3',
  removeButtons : 'Subscript,Superscript,RemoveFormat,NumberedList,Strike,Outdent,Indent,Blockquote,Styles'
};
