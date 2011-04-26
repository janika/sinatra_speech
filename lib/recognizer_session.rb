class RecognizerSession
  attr_accessor :closed_at
  attr_accessor :system_message
  attr_accessor :result
  attr :id
  attr :created_at
  
  
  def initialize
    self.created_at = Time.now
    self.id = Digest::SHA1.hexdigest(Time.now.to_s + rand(12341234).to_s)[1..10]
  end
  
  def closed?
    !closed_at.nil?
  end
  
  def to_xml
    builder = Builder::XmlMarkup.new(:indent=>2)
    builder.instruct! :xml, :version => '1.0'
    xml = builder.recognizer_session  do |b| 
      b.closed_at(self.closed_at)
      b.created_at(self.created_at) 
      b.result(self.result)
      b.id(self.id)
      b.system_message(self.system_message)
    end
    xml
  end
  
  private
  
  def id=(value)
    @id = value
  end
  
  def created_at=(value)
    @created_at=(value)
  end
end
