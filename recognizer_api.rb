$:.unshift(File.join(File.dirname(__FILE__), "lib"))
%w(gst rubygems builder sinatra recognizer recognizer_pool session_pool recognizer_session).each{|lib| require lib}
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
    set_headers
    new_session = RecognizerSession.new
    new_session.pool!
    new_session.to_xml
  rescue Exception => e
    error_to_xml(e.message)
  end
end

put '/recognizer/:id' do
  begin
    set_headers
    session = SessionPool.find_open_by_id(params[:id])
    if session
      RecognizerPool.recognize_for_session(session, request.body)
      session.to_xml
    else
      error_to_xml "Session with id #{params[:id]} not found"
    end
  rescue Exception => e
    error_to_xml(e.message)
  end
end

put '/recognizer/:id/end' do
  begin
    set_headers
    session = SessionPool.find_open_by_id(params[:id])
    if session
      session.close!
      RecognizerPool.recognize_for_session(session, nil, true)
      session.to_xml
    else
      error_to_xml("Session with id #{params[:id]} not found")
    end
  rescue Exception => e
    error_to_xml(e.message)
  end
end

get '/recognizer/:id' do
  begin
    set_headers
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
  
  def set_headers
    headers "Content-Type"=>"text/xml;charset=utf-8;"
  end
end



