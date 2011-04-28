$:.unshift(File.join(File.dirname(__FILE__), "lib"))
%w(gst rubygems builder sinatra timeout recognizer bundler recognizer_pool recognizer_session rufus/scheduler json).each{|lib| require lib}
Gst.init
Bundler.require

configure do
  set :environment, :development 
  set :raise_errors, true
  set :dump_errors, true
  set :show_exceptions, false

  $recognizer_pool = {:idle => []}

  RecognizerPool::NUMBER_OF_INITIAL_RECOGNIZERS.times do 
    RecognizerPool.pool[:idle] << Recognizer.new
  end
  
  scheduler = Rufus::Scheduler.start_new
  scheduler.every '30s' do
    RecognizerPool.clean_pool
  end
end

post '/recognizer' do
  begin
    session = RecognizerSession.new
    session.pool!
    render_with_type(session)
  rescue Exception => e
    render_error(e.message)
  end
end

put '/recognizer/:id' do
  begin
    session = RecognizerPool.find_by_session_id(params[:id])
    if session
      if session.closed?
	render_error("Session with id #{params[:id]} is already closed")
      else
	session.recognize(request.body)
	render_with_type(session)
      end
    else
      render_error("Session with id #{params[:id]} not found")
    end
  rescue Exception => e
    render_error(e.message)
  end
end

put '/recognizer/:id/end' do
  begin
    session = RecognizerPool.find_by_session_id(params[:id])
    if session
      if session.closed?
	render_error("Session with id #{params[:id]} is already closed")
      else
	session.close!
	render_with_type(session)
      end
    else
      render_error("Session with id #{params[:id]} not found")
    end
  rescue Exception => e
    render_error(e.message)
  end
end

get '/recognizer/:id' do
  begin
    session = RecognizerPool.find_by_session_id(params[:id])
    if session
      render_with_type(session)
    else
      render_error("Session with id #{params[:id]} not found")
    end
  rescue Exception => e
    render_error(e.message)
  end
end

helpers do
  
  def render_error(message)
    if response_type == "application/json"
      error_to_json(message)
    else
      error_to_xml(message)
    end
  end
  
  def error_to_json(message)
    {:error => {:message => message}}.to_json
  end
  
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
  
  def render_with_type(session)
    if response_type == "application/json"
      session.to_json
    else
      session.to_xml
    end
  end
  
  def response_type
    env['HTTP_ACCEPT']
  end
end



