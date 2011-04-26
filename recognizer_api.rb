%w(gst rubygems builder sinatra lib/recognizer lib/recognizer_pool lib/session_pool lib/recognizer_session).each{|lib| require lib}
Gst.init

configure do
  set :environment, :development 
  set :raise_errors, true
  set :dump_errors, true
  set :show_exceptions, false

  $recognizer_pool = {:idle => []}
  $session_pool = {}

  RecognizerPool::NUMBER_OF_INITIAL_RECOGNIZERS.times do 
    RecognizerPool.pool[:idle] << Recognizer.new
  end
 
end

post '/recognizer' do
  begin
    new_session = RecognizerSession.new
    new_session.pool!
    new_session.to_xml
  rescue Exception => e
    error_to_xml(e.message)
  end
end

put '/recognizer/:id' do
  begin
    request_type = env['HTTP_X_RECOGNIZER_REQUEST_TYPE']
    if request_type_not_ok?(request_type)
      error_to_xml("X-Recognizer-Request-Type must be present and set to '#{Recognizer::REQUEST_NOT_COMPLETED}' or '#{ Recognizer::REQUEST_FINAL}'")
    else
      session = SessionPool.find_open_by_id(params[:id])
      if session
	session.close! if request_type == Recognizer::REQUEST_FINAL
	RecognizerPool.recognize_for_session(session, request.body, request_type)
	session.to_xml
      else
	error_to_xml "Session with id #{params[:id]} not found"
      end
    end
  rescue Exception => e
    error_to_xml(e.message)
  end
end

get '/recognizer/:id' do
  begin
    session = SessionPool.find_by_id(params[:id])
    if session
      session.to_xml
    else
      error_to_xml("Session with id #{params[:id]} not found")
    end
  rescue Exception => e
    error_to_xml(e.message)
  end
end

helpers do
  def error_to_xml(message)
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.error do
	xml.message message
      end
    end
  end
  
  def request_type_not_ok?(request_type)
    request_type.nil? || !(Recognizer.allowed_put_request_types.include?(request_type))
  end
end



