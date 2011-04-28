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
end