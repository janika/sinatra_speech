require 'digest/sha1'
class RecognizerSession
  TIMESTAMP_FORMAT = "%F %H:%M:%S"
  BUFFER_SIZE =  2*16000
  TIMEOUT_IN_SECONDS = 5
  TIMEOUT_FOR_RECOGNITION_FAILURE = 20
  
  attr_accessor :closed_at
  attr_accessor :final_result_created_at
  attr_accessor :system_message
  attr_accessor :result
  attr_accessor :recognizer
  attr :id
  attr :created_at
  
  def initialize
    @created_at = Time.now
    @id = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..10]
  end
  
  def closed?
    !closed_at.nil?
  end
  
  def close!(end_recognizer_feed = true)
    self.closed_at = Time.now
    if recognizer
      end_feed if end_recognizer_feed
      RecognizerPool.make_recognizer_idle_if_necessary(recognizer)
    end
    self.recognizer = nil
  end
  
  def recognition_failing?
    !closed? && ((Time.now - self.created_at) > TIMEOUT_FOR_RECOGNITION_FAILURE) && (self.result.nil? || self.result.size == 0)
  end
  
  def end_feed
    begin
      timeout(TIMEOUT_IN_SECONDS) {
	self.recognizer.end_feed
      }
    rescue Timeout::Error
      self.system_message = "execution expired"
    end
    self.result = self.recognizer.result
    self.final_result_created_at = Time.now
  end
  
  def work_with_data(data)   
    while buff = data.read(BUFFER_SIZE)
      self.recognizer.feed_data(buff)
      self.result =  self.recognizer.result
    end
  end
  
  def pool!
    RecognizerPool.add_new_to_active_pool(self)
  end
  
  def recognize(data)
    if self.recognizer.nil?
      raise "Recognizer for session #{id} not found"
    else
      work_with_data(data)
    end
  end
  
  def closed_at_to_s
    if closed_at
      self.closed_at.strftime(TIMESTAMP_FORMAT)
    end
  end
  
  def final_result_created_at_to_s
    if final_result_created_at
      self.final_result_created_at.strftime(TIMESTAMP_FORMAT)
    end
  end
  
  def created_at_to_s
    if created_at
      self.created_at.strftime(TIMESTAMP_FORMAT)
    end
  end
  
  def to_xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    builder.instruct! :xml, :version => '1.0'
    xml = builder.recognizer_session  do |b| 
      b.closed_at(self.closed_at_to_s)
      b.final_result_created_at(self.final_result_created_at_to_s)
      b.created_at(self.created_at_to_s) 
      b.result(self.result)
      b.id(self.id)
      b.system_message(self.system_message)
    end
    xml
  end
  
  def to_json
    {
      :id => self.id, 
      :closed_at => self.closed_at_to_s,
      :final_result_created_at => self.final_result_created_at_to_s,
      :created_at => self.created_at_to_s,
      :result => self.result,
      :system_message => self.system_message
    }.to_json
  end
end
