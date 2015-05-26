mountApp = require './mountApp'
expect = require 'chai'.expect
element = require './element'
queryApi = require './queryApi'
retry = require 'trytryagain'
rootComponent = require '../../browser/rootComponent'

appBrowser = prototypeExtending(element) {
  adminTab() = self.find('.top-menu .tabs a', text = 'Admin')
}

adminBrowser = prototypeExtending(element) {
  searchTextBox() = self.find('.search .ui.input input')
  createUser() = self.find('.button.create')
  searchResults() = self.find('.search .results')
  result(name) = self.find('.search .results h5', text = name)
}

userBrowser = prototypeExtending(element) {
  firstName() = self.find('form.user .first-name input')
  familyName() = self.find('form.user .family-name input')
  saveButton() = self.find('form.user .button', text = 'Save')
  createButton() = self.find('form.user .button', text = 'Create')
}

describe 'admin'
  app = nil
  admin = nil
  user = nil
  api = nil
  oldFilter = nil

  beforeEach =>
    api := queryApi()
    $.mockjaxSettings.logging = false
    mountApp(rootComponent {
      user = { email = 'blah@example.com', admin = true }
    })
    app := appBrowser { selector = '.test' }
    admin := adminBrowser { selector = '.test' }
    user := userBrowser { selector = '.test' }
  
  context 'with some users'
    beforeEach =>
      api.users.push {
        id = 1
        href = '/api/users/1'
        email = 'joe@example.com'
        firstName = 'Joe'
        familyName = 'Trimble'
      }

    it 'can search for, find and edit a user' =>
      app.adminTab().click!()
      admin.searchTextBox().click!()

      admin.searchTextBox().typeIn!('joe')
      admin.result('Joe').click!()

      user.firstName().expect! @(element)
        expect(element.0.value).to.equal('Joe')

      user.firstName().typeIn!('Jack')
      user.saveButton().click!()

      retry!
        expect([u <- api.users, u.firstName]).to.eql ['Jack']

    it 'can create a new user' =>
      self.timeout 100000
      app.adminTab().click!()
      admin.createUser().click!()

      user.firstName().typeIn!('Jane')
      user.familyName().typeIn!('Jones')
      user.createButton().click!()

      admin.result('Jane').exists!()

      retry!
        expect([u <- api.users, "#(u.firstName) #(u.familyName)"]).to.eql ['Joe Trimble', 'Jane Jones']
