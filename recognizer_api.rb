$:.unshift(File.join(File.dirname(__FILE__), "lib"))

%w(gst rubygems builder sinatra timeout recognizer bundler recognizer_pool 
recognizer_session rufus/scheduler json benchmark configure helpers).each{|lib| require lib}

Gst.init
Bundler.require

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
  work_with_session
end

put '/recognizer/:id/end' do
  work_with_session(true)
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



