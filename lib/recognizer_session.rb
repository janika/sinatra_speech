class RecognizerSession
  TIMESTAMP_FORMAT = "%F %H:%M:%S"
  attr_accessor :closed_at
  attr_accessor :final_result_created_at
  attr_accessor :system_message
  attr_accessor :result
  attr :id
  attr :created_at
  
  def initialize
    @created_at = Time.now
    @id = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..10]
  end
  
  def closed?
    !closed_at.nil?
  end
  
  def close!
    self.closed_at = Time.now
  end
  
  def pool!
    RecognizerPool.add_new_to_active_pool(self)
    SessionPool.add_to_pool(self)
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
end
