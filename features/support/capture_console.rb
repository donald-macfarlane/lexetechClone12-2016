After do |scenario|
  if scenario.failed?
    page.driver.console_messages.each do |msg|
      STDOUT.puts "#{msg[:source]}(#{msg[:line_number]}) #{msg[:message]}"
    end
  end
end
