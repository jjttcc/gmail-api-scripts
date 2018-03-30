#!/usr/bin/env ruby

require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'rmail'
require 'fileutils'

class Setup

  public

  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def self.authorized_credentials
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))
    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(
        base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " +
        "resulting code after authorization"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def self.application_name
    APPLICATION_NAME
  end

  protected

  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Gmail API: send email message'
  CLIENT_SECRETS_PATH = 'client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                               "gmail-ruby-quickstart.yaml")
  SCOPE = [
    Google::Apis::GmailV1::AUTH_GMAIL_COMPOSE,
    Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
    Google::Apis::GmailV1::AUTH_GMAIL_SEND
  ]

end

class UI
  public

  def user_message(app)
    check_args
    subject = ""
    if ARGV.count > 2 && ARGV[1] == '-s' then
      subject = ARGV[2]
    end
    result = EmailMessage.new(ARGV[0], subject)
    body = $stdin.read
    if body && body.length > 0 then
      result.body = body
    end
    result
  end

  protected

  def usage
    "Usage: $0 [-s <subject>] <to-addr> ..."
  end

  def check_args
    if ARGV.count < 1 then
      puts usage
      exit 42
    end
  end

end

class EmailMessage
  attr_accessor :to_addrs, :subject, :body

  public

  def send(app)
    if to_addrs.count == 0 then
      throw "Invalid message: no <to> addresses"
    end
    message = RMail::Message.new
    message.header['To'] = to_addrs.join(',')
    #message.header['From'] = options[:from]
    message.header['Subject'] = subject
    message.body = body
    puts "Here is the message:"
    p message
exit 0
    app.service.send_user_message(app.user_id,
                              upload_source: StringIO.new(message.to_s),
                              content_type: 'message/rfc822')
  end

  protected

  def initialize(to_s, subject)
    @to_addrs = to_s
    @subject = subject
  end

end

class App
  attr_reader :service, :user_id

  def initialize
    # Initialize the API
    @user_id = 'me'
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = Setup::application_name
    @service.authorization = Setup::authorized_credentials
  end
end

ui = UI.new
app = App.new
msg = ui.user_message(app)
p msg
puts "tos: #{msg.to_addrs}"
puts "subj: #{msg.subject}"
puts "body: #{msg.body}"
msg.send(app)
send_message(service, 'jim.cochrane@gmail.com', 'send test #4', 'This be a test.')
