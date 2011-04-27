require File.dirname(__FILE__) + '/../spec_helper'

describe Recognizer do
  require 'recognizer'
  require 'fileutils'  
  
  describe "initialize" do
    it "should construct assign properties" do
      recognizer = Recognizer.new
      recognizer.pipeline.class.should == Gst::Pipeline
      recognizer.result.should == ""
      recognizer.appsrc.class.should == Gst::ElementAppSrc
      recognizer.asr.class.should == Gst::ElementPocketSphinx
      recognizer.queue.class.should == Queue
    end
    
    it "should construct pipeline" do
      pipeline = Gst::Parse.launch("appsrc name=appsrc ! audioconvert ! audioresample ! pocketsphinx name=asr ! fakesink")
      Gst::Parse.should_receive(:launch).
	with("appsrc name=appsrc ! audioconvert ! audioresample ! pocketsphinx name=asr ! fakesink").
	and_return(pipeline)
      recognizer = Recognizer.new
    end
  end
  
  it " should recognizer speech from file and clear afterwards" do
    recognizer = Recognizer.new
    session = RecognizerSession.new
    file = File.dirname(__FILE__) + '/../test_data/goforward.raw'
    recognizer.work_with_data( File.open(file,"rb"), session)
    recognizer.result.should == session.result
    recognizer.end_feed(session)
    (recognizer.result.size > 1).should be_true
    recognizer.result.should == "go forward ten leaders"
    recognizer.result.should == session.result
    session.final_result_created_at.should_not be_nil
    recognizer.clear
    recognizer.result.should == ""
  end
end