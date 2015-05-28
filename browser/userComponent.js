var prototype = require('prote');
var h = require('plastiq').html;
var form = require('./form');
var routes = require('./routes');
var userApi = require('./userApi');
var throttle = require('plastiq-throttle');
var zeroClipboard = require('plastiq-zeroclipboard');

zeroClipboard.config({ swfPath: "/static/zeroclipboard/ZeroClipboard.swf" });

module.exports = prototype({
  constructor: function (user) {
    this.user = user;
    this.userApi = userApi();

    this.getResetPasswordToken = throttle(function (user) {
      if (!user.hasPassword && user.id) {
        var self = this;

        return this.userApi.resetPasswordToken(user).then(function (response) {
          self.resetPasswordToken = response.token;
        });
      }
    });
  },

  render: function () {
    var self = this;

    this.getResetPasswordToken(this.user);

    function saveUser() {
      delete self.user.dirty;
      return self.user.save().then(function (user) {
        routes.adminUser({userId: user.id}).push();
      });
    }

    function dirtyUser(v) {
      self.user.dirty = true;
      return v;
    }

    var newUser = self.user.id === undefined;

    var user = this.user;
    var tokenLink = this.resetPasswordToken? location.origin + routes.resetPassword({token: this.resetPasswordToken}).href: undefined;

    return h('form.ui.form.user',
      newUser
        ? h('h2', 'New User')
        : h('h2',
          this.user.firstName, ' ', this.user.familyName,
          tokenLink
            ? [
                h('input.token-link', {type: 'text', value: tokenLink, onclick: function () { this.select(); }}),
                zeroClipboard(
                  tokenLink,
                  h('.ui.button.green', 'copy')
                )
              ]
            : h('span.no-token-link')
        ),
      h('.two.fields',
        form.text('First Name', [this.user, 'firstName', dirtyUser], {class: 'first-name', placeholder: 'first name'}),
        form.text('Family Name', [this.user, 'familyName', dirtyUser], {class: 'family-name', placeholder: 'family name'})
      ),
      form.text('Email', [this.user, 'email', dirtyUser], {class: 'email', placeholder: 'email'}),
      form.textarea('Address', [this.user, 'address', dirtyUser]),
      h('.two.fields',
        form.text('Office Phone Number', [this.user, 'officePhoneNumber', dirtyUser], {placeholder: 'office phone number'}),
        form.text('Cell Phone Number', [this.user, 'cellPhoneNumber', dirtyUser], {placeholder: 'cell phone number'})
      ),
      form.text('State License Number', [this.user, 'stateLicenseNumber', dirtyUser], {placeholder: 'state license number'}),
      form.boolean('Author', [this.user, 'author', dirtyUser]),
      form.boolean('Admin', [this.user, 'admin', dirtyUser]),
      h('.ui.button', {class: {disabled: !this.user.dirty, blue: !newUser, green: newUser}, onclick: saveUser}, newUser? 'Create': 'Save'),
      h('.ui.button', {onclick: routes.admin().push}, 'Close')
    );
  }
});
