require_relative 'smtp_server'

module Email
  def start_smtp_server
    @smtp_server = SmtpServer.new
    @smtp_server.start
  end

  def stop_smtp_server
    if @smtp_server
      @smtp_server.stop
    end
  end

  def received_emails
    @smtp_server.emails
  end
end

World(Email)

Before do
  start_smtp_server
end

After do
  stop_smtp_server
end
