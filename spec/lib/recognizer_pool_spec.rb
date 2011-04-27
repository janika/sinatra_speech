require File.dirname(__FILE__) + '/../spec_helper'

describe RecognizerPool do
  require 'recognizer_pool'
  before(:each) do
    Recognizer.stub!(:new).and_return(mock)
  end
  
  describe "get_for_session" do  
    it "should find for session_id" do 
      session = RecognizerSession.new
      RecognizerPool.add_new_to_active_pool(session)
      RecognizerPool.get_for_session(session.id).should_not be_nil
    end
    
    it "should raise error" do
      lambda{RecognizerPool.get_for_session("asd123")}.should raise_error("Recognizer for session asd123 not present")
    end
  end
  
  describe "add_new_to_active_pool" do
    it "should raise error" do 
      RecognizerPool.should_receive(:get_recognizer).and_return(nil)
      lambda{RecognizerPool.add_new_to_active_pool(RecognizerSession.new)}.should raise_error("No free recognizers")
    end
    
    it "should add new recognizer to active pool" do
      recognizer = Recognizer.new
      $recognizer_pool = {:idle => [recognizer]}
      RecognizerPool.pool[:idle].size.should == 1
      RecognizerPool.pool.size.should == 1
      session = RecognizerSession.new      
      RecognizerPool.add_new_to_active_pool(session)
      recognizer =  RecognizerPool.get_for_session(session.id)
      recognizer.should_not be_nil
      recognizer.should == recognizer
      RecognizerPool.pool[:idle].size.should == 0
      RecognizerPool.pool.size.should == 2
    end
  end
  
  describe "get_recognizer" do
    it "should create new instance" do
      recognizer = Recognizer.new
      $recognizer_pool = {:idle => []}
      Recognizer.should_receive(:new).and_return(recognizer)
      RecognizerPool.get_recognizer.should == recognizer
    end
    
    it "should return nil if max recognizers exceeded" do
      $recognizer_pool = {:idle => []}
      RecognizerPool::MAX_RECOGNIZERS = 0
      RecognizerPool.get_recognizer.should be_nil
    end
  end
  
  describe "recognize_for_session" do
    before(:each) do 
      @session = RecognizerSession.new
      @recognizer = Recognizer.new
    end
    
    it "should work with data" do
      RecognizerPool.should_receive(:get_for_session).with(@session.id).and_return(@recognizer)
      @recognizer.should_receive(:work_with_data).with("some data", @session).and_return(true)
      RecognizerPool.recognize_for_session(@session, "some data")
    end
    
    it "should end feed" do
      RecognizerPool.should_receive(:get_for_session).with(@session.id).and_return(@recognizer)
      @recognizer.should_receive(:end_feed).with(@session).and_return(true)
      RecognizerPool.recognize_for_session(@session, nil, true)
    end
    
    it "should raise error" do
      RecognizerPool.should_receive(:get_for_session).with(@session.id).and_return(nil)
      lambda{RecognizerPool.recognize_for_session(@session, "data")}.should raise_error("Recognizer for session #{@session.id} not found.")
    end
  end
  
  describe "collect idle" do 
    before(:each) do 
      RecognizerPool::MAX_IDLE_RECOGNIZERS = 1
      RecognizerPool::MAX_RECOGNIZERS = 2
    end
    
    it "should delete from active pool and add to idle" do
      $recognizer_pool = {:idle => []}
      session = RecognizerSession.new
      RecognizerPool.add_new_to_active_pool(session)
      SessionPool.add_to_pool(session)
      recognizer = RecognizerPool.get_for_session(session.id)
      recognizer.should_not be_nil
      session.close!
      RecognizerPool.collect_idle
      RecognizerPool.pool[:idle].size.should == 1
      RecognizerPool.pool.size.should == 1
      RecognizerPool.pool[:idle].first.should == recognizer
    end
    
    it "should not add to idle if max idles full" do
      session = RecognizerSession.new
      RecognizerPool.add_new_to_active_pool(session)
      SessionPool.add_to_pool(session)
      recognizer = RecognizerPool.get_for_session(session.id)
      recognizer.should_not be_nil
      session.close!
      RecognizerPool.collect_idle
      RecognizerPool.pool[:idle].size.should == 1
      RecognizerPool.pool.size.should == 1
      RecognizerPool.pool[:idle].first.should != recognizer
    end
  end
end