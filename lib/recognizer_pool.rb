module RecognizerPool 
  def self.pool
    $recognizer_pool
  end
  
  def self.find_by_session_id(session_id)
    pool.fetch(session_id)
  rescue IndexError
    nil   
  end
  
  def self.add_new_to_active_pool(session)
    recognizer = get_recognizer
    if !recognizer.nil?
      recognizer.clear
      session.recognizer = recognizer
      pool[session.id] = session
    else
      raise "No free recognizers"
    end
  end
  
  def self.get_recognizer
    if pool[:idle].size > 0
      pool[:idle].pop
    elsif (active_recognizers.size) < CONFIG[:max_recognizers]
      Recognizer.new
    end
  end
  
  def self.active_recognizers
    pool.collect do |session| 
      if session[0] != :idle && !session[1].recognizer.nil?
      	session[1].recognizer
      end
    end.compact
  end
  
  def self.make_recognizer_idle_if_necessary(recognizer)
    pool[:idle] << recognizer if (pool[:idle].size < CONFIG[:max_idle_recognizers])
  end
  
  def self.organize_pool
    pool.each_pair do |key, session|
      if key != :idle
	if (Time.now - session.created_at) >  CONFIG[:session_life_cycle]
	  pool.delete(key)
	elsif !session.closed? && (Time.now - session.created_at) >  CONFIG[:max_session_open_time]
	  session.close!
	  session.system_message = "Session time limit exceeded"
	elsif session.recognition_failing?
	  session.close!(false)
	  session.system_message = "Recognition not possible"
	end
      end
    end
    add_new_recognizer_to_idle_pool_if_necessary    
  end
  
  def self.add_new_recognizer_to_idle_pool_if_necessary
    if pool[:idle].empty? && ((active_recognizers.size) < CONFIG[:max_recognizers])
      pool[:idle] << Recognizer.new
    end
  end
end