Given(/^I am at the doctors$/) do
  visit '/'
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
