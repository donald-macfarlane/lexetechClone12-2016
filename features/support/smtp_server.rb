require 'eventmachine'
require 'mail'

require 'pry'

class EmailServer < EM::P::SmtpServer
  attr_accessor :emails

  def receive_plain_auth(user, pass)
    true
  end

  def get_server_domain
    "mock.smtp.server.local"
  end

  def get_server_greeting
    "mock smtp server greets you with impunity"
  end

  def receive_sender(sender)
    current.from = sender
    true
  end

  def receive_recipient(recipient)
    current.to = recipient
    true
  end

  def receive_message
    mail = Mail.new(current.data)
    @emails.push(mail)
    @current = OpenStruct.new
    true
  end

  def receive_ehlo_domain(domain)
    @ehlo_domain = domain
    true
  end

  def receive_data_command
    current.data = ""
    true
  end

  def receive_data_chunk(data)
    current.data << data.join("\n")
    true
  end

  def receive_transaction
    if @ehlo_domain
      @ehlo_domain = nil
    end
    true
  end

  def current
    @current ||= OpenStruct.new
  end

  def self.start(emails, host = 'localhost', port = 1025)
    require 'ostruct'
    @server = EM.start_server host, port, self do |session|
      session.emails = emails
    end
  end

  def self.stop
    if @server
      EM.stop_server @server
      @server = nil
    end
  end

  def self.running?
    !!@server
  end
end

class SmtpServer
  attr_reader :emails

  def initialize
    @emails = []
  end

  def start(host = 'localhost', port = 1025)
    Thread.new do
      EM.run{ EmailServer.start(emails, host, port) }
    end
  end

  def stop
    EmailServer.stop
  end
end
