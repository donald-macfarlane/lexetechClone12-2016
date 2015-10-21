Given(/^there is a user with email "(.*?)" with password "(.*?)"$/) do |email, password|
  create_user(email, password)
end

When(/^she clicks on the forgot my password link$/) do
  logout
  click_on "I forgot my password"
end

When(/^she enters her email address "(.*?)"$/) do |email|
  fill_in "Email", with: email
  click_on "Reset"
end

Then(/^she receives an email with a reset password link$/) do
  def password_reset_emails
    received_emails.select do |mail|
      mail.subject =~ /password reset/i
    end
  end

  wait_for do
    expect(password_reset_emails.size).to be > 0
  end

  html = password_reset_emails[0].html_part.decoded
  @reset_password_link = Nokogiri::HTML(html).css('a').attr('href').value
end

When(/^she clicks on the reset password link$/) do
  visit @reset_password_link
end

Then(/^she can enter a new password "(.*?)"$/) do |password|
  fill_in "Password", with: password
  find('.button', text: "LOGIN").click
end
