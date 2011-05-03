require File.dirname(__FILE__) + '/../spec_helper'

describe RecognizerPool do
  require 'recognizer_pool'
  before(:each) do
    Recognizer.stub!(:new).and_return(mock(:clear => true))
  end
  
  describe "find_by_session_id" do  
    it "should find for session_id" do 
      session = RecognizerSession.new
      RecognizerPool.add_new_to_active_pool(session)
      RecognizerPool.find_by_session_id(session.id).should_not be_nil
    end
    
    it "should be nil" do
      RecognizerPool.find_by_session_id("asd123").should be_nil
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
      recognizer.should_receive(:clear).and_return(true)
      RecognizerPool.add_new_to_active_pool(session)
      session =  RecognizerPool.find_by_session_id(session.id)
      session.should_not be_nil
      session.recognizer.should == recognizer
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
    
  describe "organize_pool" do
    before(:each) do 
      RecognizerPool::MAX_RECOGNIZERS = 1
      $recognizer_pool = {:idle => []}
    end
    
    it "should close session if open time exceeded" do
      time = (Time.now - (RecognizerPool::MAX_OPEN_TIME_IN_SECONDS + 10))
      session = RecognizerSession.new
      session.stub!(:created_at).and_return(time)
      RecognizerPool.add_new_to_active_pool(session)
      session.recognizer.should_not be_nil
      RecognizerPool.find_by_session_id(session.id).should == session
      
      session.should_receive(:end_feed).and_return(true)
      RecognizerPool.organize_pool
      
      RecognizerPool.find_by_session_id(session.id).should == session
      session.recognizer.should be_nil
      session.closed_at.should_not be_nil
      session.system_message.should == "Session time limit exceeded"
    end
    
    it "should close session without ending feed if recognition failing" do
      session = RecognizerSession.new
      RecognizerPool.add_new_to_active_pool(session)
      session.recognizer.should_not be_nil
      RecognizerPool.find_by_session_id(session.id).should == session
      session.should_receive(:recognition_failing?).and_return(true)
      session.should_not_receive(:end_feed)
      RecognizerPool.organize_pool
      
      RecognizerPool.find_by_session_id(session.id).should == session
      session.recognizer.should be_nil
      session.closed_at.should_not be_nil
      session.system_message.should == "Recognition not possible"
    end
    
    it "should remove session if maximum life time exceeded" do
      time = (Time.now - (RecognizerPool::LIFE_CYCLE_IN_SECONDS + 10))
      session = RecognizerSession.new
      session.stub!(:created_at).and_return(time)
      RecognizerPool.add_new_to_active_pool(session)
      RecognizerPool.find_by_session_id(session.id).should == session
      RecognizerPool.organize_pool
      RecognizerPool.find_by_session_id(session.id).should be_nil
    end
    
    it "should preserve session, if no time limit exceeded" do
      session = RecognizerSession.new
      RecognizerPool.add_new_to_active_pool(session)
      RecognizerPool.find_by_session_id(session.id).should == session
      RecognizerPool.organize_pool
      RecognizerPool.find_by_session_id(session.id).should == session
    end
    
    it "should receive add_new_recognizer_to_idle_pool_if_necessary" do
      session = RecognizerSession.new
      RecognizerPool.should_receive(:add_new_recognizer_to_idle_pool_if_necessary)
      RecognizerPool.organize_pool
    end
  end
  
  describe "add_new_recognizer_to_idle_pool_if_necessary" do
    it "should add new recognizer to idle pool if idle pool is empty and max is not exceeded" do
      RecognizerPool::MAX_RECOGNIZERS = 1
      $recognizer_pool = {:idle => []}
      RecognizerPool.pool[:idle].size.should == 0
      Recognizer.should_receive(:new).and_return(mock)
      RecognizerPool.add_new_recognizer_to_idle_pool_if_necessary
      RecognizerPool.pool[:idle].size.should == 1
    end
    
    it "should not create new recognizer if idle pool not empty" do
      $recognizer_pool = {:idle => [mock]}
      current_idle_pool_size = RecognizerPool.pool[:idle].size
      Recognizer.should_not_receive(:new).and_return(mock)
      RecognizerPool.add_new_recognizer_to_idle_pool_if_necessary
      RecognizerPool.pool[:idle].size.should == current_idle_pool_size      
    end
    
    it "should not create new recognizer if max recognizers limit exceeded" do
      RecognizerPool::MAX_RECOGNIZERS = 2
      $recognizer_pool = {:idle => []}
      current_idle_pool_size = RecognizerPool.pool[:idle].size
      RecognizerPool.should_receive(:active_recognizers).and_return([mock, mock])
      Recognizer.should_not_receive(:new).and_return(mock)
      RecognizerPool.add_new_recognizer_to_idle_pool_if_necessary
      RecognizerPool.pool[:idle].size.should == current_idle_pool_size
    end
  end
  
  describe "active_recognizers" do
    it "should return active recognizers" do
      recognizer_1 = mock
      recognizer_2 = mock
      session_1 =  RecognizerSession.new
      session_1.recognizer = recognizer_1
      session_2 =  RecognizerSession.new
      session_2.recognizer = recognizer_2
      $recognizer_pool = {
	"1" => session_1,
	"2" => session_2,
	"3" => RecognizerSession.new,
	:idle => [mock]}
      active = RecognizerPool.active_recognizers
      active.size.should == 2
      active.include?(recognizer_1).should be_true
      active.include?(recognizer_2).should be_true
    end
  end
  
  describe "make_recognizer_idle_if_necessary" do
    before(:each) do
      RecognizerPool::MAX_IDLE_RECOGNIZERS = 1
    end
    
    it "should add to idle pool" do
      $recognizer_pool = {:idle => []}
      recognizer = mock
      RecognizerPool.pool[:idle].should == []
      RecognizerPool.make_recognizer_idle_if_necessary(recognizer)
      RecognizerPool.pool[:idle].size.should == 1
      RecognizerPool.pool[:idle].include?(recognizer).should be_true
    end
    
    it "should not add to idle pool" do
      $recognizer_pool = {:idle => [mock]}
      recognizer = mock
      RecognizerPool.pool[:idle].size.should == 1
      RecognizerPool.make_recognizer_idle_if_necessary(recognizer)
      RecognizerPool.pool[:idle].size.should == 1
      RecognizerPool.pool[:idle].include?(recognizer).should be_false
    end
  end
end