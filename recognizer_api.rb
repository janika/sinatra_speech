%w(gst rubygems sinatra lib/speech_recognition lib/recognizer_pool lib/session_pool lib/recognizer_session).each{|lib| require lib}
Gst.init

configure do
  set :environment, :development 
  set :raise_errors, true
  set :dump_errors, true
  set :show_exceptions, false

  $recognizer_pool = {:idle => []}
  $session_pool = {}

  RecognizerPool::NUMBER_OF_INITIAL_RECOGNIZERS.times do 
    RecognizerPool.pool[:idle] << SpeechRecognition::Recognizer.new
  end
 
end

post '/recognizer' do
  new_session = RecognizerSession.new
  SessionPool.add_to_pool(new_session)
  RecognizerPool.add_new_to_active_pool(new_session)
  builder do |xml|
    xml.instruct! :xml, :version => '1.0'
    xml.rss :version => "2.0" do
      xml.recognizer_session do
	xml.closed_at new_session.closed_at
	xml.created_at new_session.created_at
	xml.result new_session.result
	xml.id new_session.id
	xml.system_message new_session.system_message
      end
    end
  end
end

put '/recognizer/:id' do
  session = SessionPool.find_open_by_id(params[:id])
  if session && !params[:file].nil?
    file = "tmp/#{params[:file][:filename]}"
    File.open(file, 'wb') do |f|
      f.write params[:file][:tempfile].read
    end
    
    recognizer = RecognizerPool.get_for_session(session.id)  
    #recognizer.work_with_file(file, session)
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.rss :version => "2.0" do
	xml.recognizer_session do
	  xml.closed_at session.closed_at
	  xml.created_at session.created_at
	  xml.result session.result
	  xml.id session.id
	  xml.system_message session.system_message
	end
      end
    end
  else
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.rss :version => "2.0" do
	xml.error do
	  xml.message "Session with id #{params[:id]} not found"
	end
      end
    end
  end
end

get '/recognizer/:id' do
  session = SessionPool.find_by_id(params[:id])
  if session
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.rss :version => "2.0" do
	xml.recognizer_session do
	  xml.closed_at session.closed_at
	  xml.created_at session.created_at
	  xml.result session.result
	  xml.id session.id
	  xml.system_message session.system_message
	end
      end
    end
  else
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.rss :version => "2.0" do
	xml.error do
	  xml.message "Session with id #{params[:id]} not found"
	end
      end
    end
  end
end




