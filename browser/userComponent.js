var prototype = require('prote');
var h = require('plastiq').html;
var form = require('./form');
var routes = require('./routes');

module.exports = prototype({
  constructor: function (user) {
    this.user = user;
  },

  render: function () {
    var self = this;

    function saveUser() {
      delete self.user.dirty;
      return self.user.update();
    }

    function dirtyUser(v) {
      self.user.dirty = true;
      return v;
    }

    var user = this.user;
    return h('form.ui.form.user',
      h('.two.fields',
        form.text('First Name', [this.user, 'firstName', dirtyUser], {class: 'first-name', placeholder: 'first name'}),
        form.text('Family Name', [this.user, 'familyName', dirtyUser], {class: 'family-name', placeholder: 'family name'})
      ),
      form.text('Email', [this.user, 'email', dirtyUser], {placeholder: 'email'}),
      form.textarea('Address', [this.user, 'address', dirtyUser]),
      h('.two.fields',
        form.text('Office Phone Number', [this.user, 'officePhoneNumber', dirtyUser], {placeholder: 'office phone number'}),
        form.text('Cell Phone Number', [this.user, 'cellPhoneNumber', dirtyUser], {placeholder: 'cell phone number'})
      ),
      form.text('State License Number', [this.user, 'stateLicenseNumber', dirtyUser], {placeholder: 'state license number'}),
      form.boolean('Author', [this.user, 'author', dirtyUser]),
      form.boolean('Admin', [this.user, 'admin', dirtyUser]),
      h('.ui.button.blue', {class: {disabled: !this.user.dirty}, onclick: saveUser}, 'Save'),
      h('.ui.button', {onclick: routes.admin().push}, 'Close')
    );
  }
});
