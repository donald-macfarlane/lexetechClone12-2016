Given(/^there are no blocks$/) do
  api.load_lexicon("emptyLexicon.json")
end

When(/^I create the block "(.*?)"$/) do |name|
  @block_name = name
  visit '/authoring'
  click_on 'New Block'
  fill_in 'new_block_name', with: name
  click_on 'Create Block'
end

Then(/^I should arrive at the block$/) do
  expect(page).to have_content(@block_name)
end

Given(/^the block "(.*?)" exists$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

When(/^I add the query "(.*?)"$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^I can add responses to the query$/) do
  pending # express the regexp above with the code you wish you had
end

Given(/^the query "(.*?)" exists$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

When(/^I add the response "(.*?)"$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^I can compose notes about Heamatology$/) do
  pending # express the regexp above with the code you wish you had
end