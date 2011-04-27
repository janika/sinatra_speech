require File.dirname(__FILE__) + '/../spec_helper'

describe SessionPool do
  require 'session_pool'
  
  it "pool should be equal to global session pool" do 
    SessionPool.pool.should == $session_pool
    SessionPool.add_to_pool(RecognizerSession.new)
    SessionPool.pool.should == $session_pool
  end
  
  it "add session to pool should increase pool" do
    session = RecognizerSession.new
    original_size = SessionPool.pool.size
    SessionPool.add_to_pool(session)
    SessionPool.pool.size.should == original_size + 1
  end
  
  describe "fetching from pool" do
    before(:each) do 
      @session = RecognizerSession.new
      SessionPool.add_to_pool(@session)
    end
    
    describe "find by id" do
      it "should return open session" do
	SessionPool.find_by_id(@session.id).should == @session
      end
      
      it "should return closed session" do
	@session.close!
	SessionPool.find_by_id(@session.id).should == @session
      end
      
      it "should return nil if id not present" do
	SessionPool.find_by_id("not_present_id").should be_nil
      end
    end
    
    describe "find open by id" do
      it "should return session" do 
	SessionPool.find_open_by_id(@session.id).should == @session
      end
      
      it "should return nil if session closed" do 
	@session.close!
	SessionPool.find_open_by_id(@session.id).should be_nil
      end
    end
  end
  
  describe "clean_pool" do
    before(:each) do 
      $session_pool = {}
    end
    
    it "should close session if open time exceeded" do
      time = (Time.now - (SessionPool::MAX_OPEN_TIME_IN_SECONDS + 10))
      session = RecognizerSession.new
      session.stub!(:created_at).and_return(time)
      SessionPool.add_to_pool(session)
      SessionPool.find_by_id(session.id).should == session
      SessionPool.clean_pool
      SessionPool.find_by_id(session.id).should == session
      SessionPool.find_open_by_id(session.id).should be_false
      session.system_message.should == "Session time limit exceeded"
      session.closed_at.nil?.should be_false
    end
    
    it "should remove session if maximum life time exceeded" do
      time = (Time.now - (SessionPool::LIFE_CYCLE_IN_SECONDS + 10))
      session = RecognizerSession.new
      session.stub!(:created_at).and_return(time)
      SessionPool.add_to_pool(session)
      SessionPool.find_by_id(session.id).should == session
      SessionPool.clean_pool
      SessionPool.find_by_id(session.id).should be_nil
    end
    
    it "should preserve session, if no time limit exceeded" do
      session = RecognizerSession.new
      SessionPool.add_to_pool(session)
      SessionPool.find_by_id(session.id).should == session
      SessionPool.clean_pool
      SessionPool.find_by_id(session.id).should == session
      SessionPool.find_open_by_id(session.id).should == session
    end
  end
end