require File.dirname(__FILE__) + '/../spec_helper'

describe RecognizerSession do
  require 'recognizer_session'
  
  describe "initialize" do
    it "should assign created_at and id" do
      session = RecognizerSession.new
      session.id.should_not be_nil
      session.created_at.should_not be_nil
    end
  end
  
  describe "closed?" do
    it "should be true" do
      RecognizerSession.new.closed?.should be_false
    end
    
    it "should be false" do
      session = RecognizerSession.new
      session.closed_at = Time.now
      session.closed?.should be_true
    end
  end
  
  describe "close!" do
    it "should assign closed_at" do
      session = RecognizerSession.new
      session.close!
      session.closed_at.should_not be_nil
    end
  end
  
  describe "pool!" do
    it "should add to session and recogniser pool" do
      original_recognizer_pool_size = RecognizerPool.pool.size
      session_pool_size = SessionPool.pool.size
      session = RecognizerSession.new
      session.pool!
      RecognizerPool.pool.size.should == original_recognizer_pool_size + 1
      SessionPool.pool.size.should == session_pool_size + 1
      SessionPool.find_open_by_id(session.id).should == session
      RecognizerPool.get_for_session(session.id).should_not be_nil
    end
  end
  
  describe "closed_at_to_s" do
    it "should return closed_at in correct format" do
      session = RecognizerSession.new
      time = Time.now
      session.closed_at = time
      session.closed_at_to_s.should == time.strftime(RecognizerSession::TIMESTAMP_FORMAT)
    end
    
    it "should return nil" do
      RecognizerSession.new.closed_at_to_s.should be_nil
    end
  end

  describe "final_result_created_at_to_s" do
    it "should return closed_at in correct format" do
      session = RecognizerSession.new
      time = Time.now
      session.final_result_created_at = time
      session.final_result_created_at_to_s.should == time.strftime(RecognizerSession::TIMESTAMP_FORMAT)
    end
    
    it "should return nil" do
      RecognizerSession.new.final_result_created_at_to_s.should be_nil
    end
  end
  
  describe "created_at_to_s" do
    it "should return closed_at in correct format" do
      time = Time.now
      Time.stub!(:now).and_return(time)
      session = RecognizerSession.new
      session.created_at_to_s.should == time.strftime(RecognizerSession::TIMESTAMP_FORMAT)
    end
  end
  
  describe "to_xml" do
    it "should include session properties" do
      time = Time.now
      Time.stub!(:now).and_return(time)
      session = RecognizerSession.new
      session.result = "Result"
      session.closed_at = time
      session.final_result_created_at = time
      session.system_message = "Message"
      session.to_xml.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<recognizer_session>\n  <closed_at>#{time.strftime(RecognizerSession::TIMESTAMP_FORMAT)}</closed_at>\n  <final_result_created_at>#{time.strftime(RecognizerSession::TIMESTAMP_FORMAT)}</final_result_created_at>\n  <created_at>#{time.strftime(RecognizerSession::TIMESTAMP_FORMAT)}</created_at>\n  <result>Result</result>\n  <id>#{session.id}</id>\n  <system_message>Message</system_message>\n</recognizer_session>\n" 
    end
  end
end