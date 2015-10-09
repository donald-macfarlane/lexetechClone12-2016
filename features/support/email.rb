require_relative 'smtp_server'

module Email
  def start_smtp_server
    @server = SmtpServer.new
    @server.start
  end

  def received_emails
    @server.emails
  end
end

World(Email)

Before('@smtp') do
  start_smtp_server
end
