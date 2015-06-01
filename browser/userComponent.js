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
    this.validationPromises = 0;

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

    function saveUser(formElement) {
      var promise = self.validation.then(function () {
        delete self.user.dirty;
        delete self.validation;

        return self.user.save().then(function (user) {
          routes.adminUser({userId: user.id}).push();
        });
      }, function () {
        delete self.validation;
      });

      formElement.form('validate form');

      return promise;
    }

    function dirtyUser(v) {
      self.user.dirty = true;
      return v;
    }

    var newUser = self.user.id === undefined;

    var user = this.user;
    var tokenLink = this.resetPasswordToken? location.origin + routes.resetPassword({token: this.resetPasswordToken}).href: undefined;

    if (!this.validation) {
      this.validationPromises++;
      this.validation = new Promise(function (fulfil, reject) {
        var x = self.validationPromises;
        self.onSuccess = fulfil;
        self.onFailure = reject;
      });
    }

    return form.form(
      {
        email: {
          identifier: 'email',
          rules: [{
            type: 'email',
            prompt: 'please enter a valid email address'
          }]
        }
      },
      {
        onSuccess: function () {
          return self.onSuccess.apply(self, arguments);
        },
        onFailure: function () {
          return self.onFailure.apply(self, arguments);
        }
      },
      function (component) {
        var formElement = component.state.formElement;

        return h('form.ui.form.user',
          newUser
            ? h('h2', 'New User')
            : h('h2',
              self.user.firstName, ' ', self.user.familyName,
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
            form.text('First Name', [self.user, 'firstName', dirtyUser], {class: 'first-name', placeholder: 'first name'}),
            form.text('Family Name', [self.user, 'familyName', dirtyUser], {class: 'family-name', placeholder: 'family name'})
          ),
          form.text('Email', [self.user, 'email', dirtyUser], {class: 'email', placeholder: 'email', name: 'email'}),
          form.textarea('Address', [self.user, 'address', dirtyUser]),
          h('.two.fields',
            form.text('Office Phone Number', [self.user, 'officePhoneNumber', dirtyUser], {placeholder: 'office phone number'}),
            form.text('Cell Phone Number', [self.user, 'cellPhoneNumber', dirtyUser], {placeholder: 'cell phone number'})
          ),
          form.text('State License Number', [self.user, 'stateLicenseNumber', dirtyUser], {placeholder: 'state license number'}),
          form.boolean('Author', [self.user, 'author', dirtyUser]),
          form.boolean('Admin', [self.user, 'admin', dirtyUser]),
          h('.ui.button', {class: {disabled: !self.user.dirty, blue: !newUser, green: newUser}, onclick: function () { return saveUser(formElement); }}, newUser? 'Create': 'Save'),
          h('.ui.button', {onclick: routes.admin().push}, 'Close')
        );
      }
    );
  }
});
