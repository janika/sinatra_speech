require File.dirname(__FILE__) + '/spec_helper'

describe "Recognizer API" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  describe "get recognizer" do
    
    it "should be add active to recognizer pool" do
      RecognizerPool.pool.size.should == 1
      RecognizerPool.pool[:idle].size.should == RecognizerPool::NUMBER_OF_INITIAL_RECOGNIZERS
      post '/recognizer'
      last_response.should be_ok
      RecognizerPool.pool.size.should == 2
      RecognizerPool.pool[:idle].size.should == (RecognizerPool::NUMBER_OF_INITIAL_RECOGNIZERS - 1)
    end
    
    it "should be success" do
      post '/recognizer'
      last_response.should be_ok      
    end
    
    it "should return xml" do
      session = RecognizerSession.new
      RecognizerSession.should_receive(:new).and_return(session)
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      post '/recognizer'
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<recognizer_session>\n  <closed_at></closed_at>\n  <final_result_created_at></final_result_created_at>\n  <created_at>created_at</created_at>\n  <result></result>\n  <id>id</id>\n  <system_message></system_message>\n</recognizer_session>\n"
    end
    
    it "should add to session pool" do
      last_size = SessionPool.pool.size
      post '/recognizer'
      SessionPool.pool.size.should == last_size + 1
    end
  end
end
