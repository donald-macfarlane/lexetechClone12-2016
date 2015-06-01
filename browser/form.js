var h = require('plastiq').html;
var semanticUi = require('plastiq-semantic-ui');

module.exports = {
  form: function (options, settings, vdom) {
    return semanticUi.form(options, settings, vdom);
  },

  text: function (label, binding, options) {
    return this.field(label, binding, options);
  },

  boolean: function (label, binding, options) {
    binding = h.binding(binding);

    return h('.field',
      semanticUi.checkbox({binding: binding},
        h('.ui.toggle.checkbox',
          h('input', {type: 'checkbox'}),
          h('label', label)
        )
      )
    );
  },

  textarea: function (label, binding, options) {
    var placeholder = options && options.hasOwnProperty('placeholder') && options.placeholder !== undefined? options.placeholder: 'text';

    return h('.field',
      h('label', label),
      h('.ui.input',
        h('textarea', {placeholder: placeholder, binding: binding})
      )
    );
  },

  field: function (label, binding, options) {
    var type = options && options.hasOwnProperty('type') && options.type !== undefined? options.type: 'text';
    var placeholder = options && options.hasOwnProperty('placeholder') && options.placeholder !== undefined? options.placeholder: 'text';
    var _class = options && options.hasOwnProperty('class') && options.class !== undefined? options.class: undefined;
    var name = options && options.hasOwnProperty('name') && options.name !== undefined? options.name: undefined;

    return h('.field', {class: _class},
      h('label', label),
      h('.ui.input',
        h('input', {type: type, placeholder: placeholder, binding: binding, name: name})
      )
    );
  }
};

