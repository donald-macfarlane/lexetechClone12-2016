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

Given(/^the doctor has an account$/) do
  @doctors_email = "doctor@surgery.com"
  @doctors_password = "Wowz3rs"
  api.sign_up(@doctors_email, @doctors_password)
end

Given(/^the doctor has signed in$/) do
  login(@doctors_email, @doctors_password)
end

Given(/^there are some queries$/) do
  api.load_lexicon("smallLexicon.json")
end

Given(/^there is a comprehensive lexicon$/) do
  api.load_lexicon("lexicon.json")
end
