mountApp = require './mountApp'
expect = require 'chai'.expect
element = require './element'
queryApi = require './queryApi'
retry = require 'trytryagain'

appBrowser = prototypeExtending(element) {
  adminTab() = self.find('.top-menu .tabs a', text = 'Admin')
}

adminBrowser = prototypeExtending(element) {
  searchTextBox() = self.find('.ui.search input')
  searchResults() = self.find('.ui.search .results .content')
  result(name) = self.find('.ui.search .results .content', text = name)
}

userBrowser = prototypeExtending(element) {
  firstName() = self.find('form.user .first-name input')
  saveButton() = self.find('form.user .button', text = 'Save')
}

describe 'admin'
  app = nil
  admin = nil
  user = nil
  api = nil
  oldFilter = nil

  beforeEach =>
    self.timeout 100000
    api := queryApi()
    $.mockjaxSettings.logging = false
    mountApp {
      user = { email = 'blah@example.com', admin = true }
    }
    app := appBrowser { selector = '.test' }
    admin := adminBrowser { selector = '.test' }
    user := userBrowser { selector = '.test' }
  
  context 'with some users'
    beforeEach =>
      self.timeout 100000
      api.users.push {
        id = 1
        href = '/api/users/1'
        email = 'joe@example.com'
        firstName = 'Joe'
        familyName = 'Trimble'
      }

    it 'can search for, find and edit a user' =>
      self.timeout 100000
      app.adminTab().click!()
      admin.searchTextBox().exists!()
      admin.searchTextBox().click!()

      admin.searchTextBox().typeIn!('joe')
      admin.result('Joe').click!()

      user.firstName().expect! @(element)
        expect(element.0.value).to.equal('Joe')

      user.firstName().typeIn!('Jack')
      user.saveButton().click!()

      retry!
        expect([u <- api.users, u.firstName]).to.eql ['Jack']
