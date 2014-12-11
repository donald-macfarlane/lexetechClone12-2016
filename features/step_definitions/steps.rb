require 'rest_client'

Given(/^I am at the doctors$/) do
  visit '/'
end

Given(/^the doctor has signed in with email "(.*?)" and password "(.*?)"$/) do |email, password|
  login(email, password)
end

When(/^the doctor asks me "(.*?)"$/) do |query_text|
  expect(page).to have_content(query_text)
end

When(/^I answer "(.*?)"$/) do |response|
  click_on response
end

Then(/^the doctor makes the following notes:$/) do |string|
  within '.notes' do
    expect(page).to have_content(string)
  end
end

def create_user(email, password)
  visit '/'
  click_on "Sign up"
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_on "Create"
end

def login(email, password)
  visit '/'
  click_on "Log in"
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_on "Login"
end

When(/^I create a new user with email address "(.*?)" and password "(.*?)"$/) do |email, password|
  create_user(email, password)
end

Then(/^I can see the first question$/) do
  expect(page).to have_content('What hurts?')
end

Given(/^I have created a user previously with email address "(.*?)" and password "(.*?)"$/) do |email, password|
  create_user(email, password)
end

Given(/^I have logged out$/) do
  click_on 'Logout'
end

When(/^I log in with email address "(.*?)" and password "(.*?)"$/) do |email, password|
  login(email, password)
end

def load_lexicon(filename)
  json = File.read(filename)
  RestClient.post "http://api:squidandeels@localhost:8001/api/queries",
     json,
     :content_type => :json,
     :accept => :json
end

Given(/^there are some queries$/) do
  load_lexicon(File.expand_path('../../support/smallLexicon.json', __FILE__))
end

Given(/^there is a comprehensive lexicon$/) do
  load_lexicon(File.expand_path('../../support/lexicon.json', __FILE__))
end
