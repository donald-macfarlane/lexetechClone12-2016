module LoginAutomation
  def create_user(email, password)
    visit '/signup'
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_on "Create"
  end

  def login(email, password)
    visit '/login'
    fill_in "Email", with: email
    fill_in "Password", with: password
    click_button "Log in"
  end

  def logout
    click_on 'Logout'
  end
end

World(LoginAutomation)
