configure do
  set :environment, :development 
  set :raise_errors, true
  set :dump_errors, true
  set :show_exceptions, false

  $recognizer_pool = {:idle => []}
  CONFIG = {
    :nr_of_initial_recognizers => 4, #the number of recognizers initialized when server is started
    :max_idle_recognizers => 4, #number of recognizer instances that are allowed to be idle
    :max_recognizers => 4, #total amount of allowed recognizers
    :session_life_cycle => 10 * 60, #the amount of seconds the session result is kept in memory
    :max_session_open_time => 3 * 60, #amount of seconds during which the session is kept open and speech is received
    :timeout_in_seconds => 10, #session closed if after ending feed during 10 seconds no final result is given from recognizer
    :timeout_for_recognition_failure => 60 #session is closed by system if after 60 seconds no result is generated for session
  }

  CONFIG[:nr_of_initial_recognizers].times do 
    RecognizerPool.pool[:idle] << Recognizer.new
  end
  
  scheduler = Rufus::Scheduler.start_new
  scheduler.every '120s' do
    RecognizerPool.organize_pool
  end
end