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
end