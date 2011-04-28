require File.dirname(__FILE__) + '/spec_helper'

describe "Recognizer API" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  describe "POST recognizer" do
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
    
    it "should return json" do
      session = RecognizerSession.new
      RecognizerSession.should_receive(:new).and_return(session)
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      post '/recognizer', {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should == "{\"created_at\":\"created_at\",\"system_message\":null,\"result\":null,\"final_result_created_at\":null,\"id\":\"id\",\"closed_at\":null}"
    end
    
    it "should add to session pool" do
      last_size = SessionPool.pool.size
      post '/recognizer'
      SessionPool.pool.size.should == last_size + 1
    end
    
    it "should respond with error xml if pool limit exceeded" do
      RecognizerPool.should_receive(:get_recognizer).and_return(nil)
      post '/recognizer'
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <message>No free recognizers</message>\n</error>\n"
    end
    
    it "should respond with error json if pool limit exceeded" do
      RecognizerPool.should_receive(:get_recognizer).and_return(nil)
      post '/recognizer', {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should == "{\"error\":{\"message\":\"No free recognizers\"}}"
    end
  end
  
  describe "GET recognizer" do
    it "should be success" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      SessionPool.should_receive(:find_by_id).with("asd123").and_return(session)
      get "/recognizer/asd123"
      last_response.should be_ok
    end
    
    it "should return session xml" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      session.should_receive(:result).and_return("Hello World!")
      session.should_receive(:final_result_created_at_to_s).and_return("Final time")
      session.should_receive(:closed_at_to_s).and_return("Closed at")
      session.should_receive(:system_message).and_return("Recognizer closed")
      SessionPool.should_receive(:find_by_id).with("asd123").and_return(session)
      get "/recognizer/asd123"
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<recognizer_session>\n  <closed_at>Closed at</closed_at>\n  <final_result_created_at>Final time</final_result_created_at>\n  <created_at>created_at</created_at>\n  <result>Hello World!</result>\n  <id>id</id>\n  <system_message>Recognizer closed</system_message>\n</recognizer_session>\n"
    end
    
    it "should return session json" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      session.should_receive(:result).and_return("Hello World!")
      session.should_receive(:final_result_created_at_to_s).and_return("Final time")
      session.should_receive(:closed_at_to_s).and_return("Closed at")
      session.should_receive(:system_message).and_return("Recognizer closed")
      SessionPool.should_receive(:find_by_id).with("asd123").and_return(session)
      get "/recognizer/asd123", {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should == "{\"created_at\":\"created_at\",\"system_message\":\"Recognizer closed\",\"result\":\"Hello World!\",\"final_result_created_at\":\"Final time\",\"id\":\"id\",\"closed_at\":\"Closed at\"}"
    end
    
    it "should return error xml if session not found" do
      get "/recognizer/asd123"
      last_response.should be_ok
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>\n  <message>Session with id asd123 not found</message>\n</error>\n"
    end  
    
    it "should return error json if session not found" do
      get "/recognizer/asd123", {}, "HTTP_ACCEPT" => "application/json"
      last_response.should be_ok
      last_response.body.should == "{\"error\":{\"message\":\"Session with id asd123 not found\"}}"
    end  
  end
  
  describe "PUT recognizer" do 
    it "should be success" do
      put "/recognizer/asd123"
      last_response.should be_ok
    end

    it "should return session xml" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      session.should_receive(:result).and_return("Hello World!")
      session.should_receive(:final_result_created_at_to_s).and_return("Final time")
      session.should_receive(:closed_at_to_s).and_return("Closed at")
      session.should_receive(:system_message).and_return("Recognizer closed")
      SessionPool.should_receive(:find_open_by_id).with("asd123").and_return(session)
      RecognizerPool.should_receive(:recognize_for_session).and_return(true)
      put "/recognizer/asd123"
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<recognizer_session>\n  <closed_at>Closed at</closed_at>\n  <final_result_created_at>Final time</final_result_created_at>\n  <created_at>created_at</created_at>\n  <result>Hello World!</result>\n  <id>id</id>\n  <system_message>Recognizer closed</system_message>\n</recognizer_session>\n"
    end
    
    it "should return session json" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      session.should_receive(:result).and_return("Hello World!")
      session.should_receive(:final_result_created_at_to_s).and_return("Final time")
      session.should_receive(:closed_at_to_s).and_return("Closed at")
      session.should_receive(:system_message).and_return("Recognizer closed")
      SessionPool.should_receive(:find_open_by_id).with("asd123").and_return(session)
      RecognizerPool.should_receive(:recognize_for_session).and_return(true)
      put "/recognizer/asd123", {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should == "{\"created_at\":\"created_at\",\"system_message\":\"Recognizer closed\",\"result\":\"Hello World!\",\"final_result_created_at\":\"Final time\",\"id\":\"id\",\"closed_at\":\"Closed at\"}" 
    end
  end
  
  describe "PUT recognizer/id/end" do
    it "should close session" do
      session = RecognizerSession.new
      SessionPool.should_receive(:find_open_by_id).with("asd123").and_return(session)
      put "/recognizer/asd123/end"
      session.closed_at.should_not be_nil
    end
    
    it "should return session xml" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      session.should_receive(:result).and_return("Hello World!")
      session.should_receive(:final_result_created_at_to_s).and_return("Final time")
      session.should_receive(:closed_at_to_s).and_return("Closed at")
      session.should_receive(:system_message).and_return("Recognizer closed")
      SessionPool.should_receive(:find_open_by_id).with("asd123").and_return(session)
      RecognizerPool.should_receive(:recognize_for_session).with(session, nil, true).and_return(true)
      put "/recognizer/asd123/end"
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<recognizer_session>\n  <closed_at>Closed at</closed_at>\n  <final_result_created_at>Final time</final_result_created_at>\n  <created_at>created_at</created_at>\n  <result>Hello World!</result>\n  <id>id</id>\n  <system_message>Recognizer closed</system_message>\n</recognizer_session>\n"
    end
    
    it "should return session json" do
      session = RecognizerSession.new
      session.stub!(:id).and_return('id')
      session.should_receive(:created_at_to_s).and_return("created_at")
      session.should_receive(:result).and_return("Hello World!")
      session.should_receive(:final_result_created_at_to_s).and_return("Final time")
      session.should_receive(:closed_at_to_s).and_return("Closed at")
      session.should_receive(:system_message).and_return("Recognizer closed")
      SessionPool.should_receive(:find_open_by_id).with("asd123").and_return(session)
      RecognizerPool.should_receive(:recognize_for_session).with(session, nil, true).and_return(true)
      put "/recognizer/asd123/end", {}, "HTTP_ACCEPT" => "application/json"
      last_response.body.should ==  "{\"created_at\":\"created_at\",\"system_message\":\"Recognizer closed\",\"result\":\"Hello World!\",\"final_result_created_at\":\"Final time\",\"id\":\"id\",\"closed_at\":\"Closed at\"}"
    end
  end
end
