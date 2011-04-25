require 'gst'
require 'sinatra'
require 'lib/speech_recognition'
require "lib/recognizer_pool"
require "lib/session_pool"
require "lib/recognizer_session"

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
end

put '/recognizer/:id' do
end

get '/recognizer/:id' do
end




