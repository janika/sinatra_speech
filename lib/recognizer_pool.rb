module RecognizerPool
  MAX_IDLE_RECOGNIZERS = 2
  NUMBER_OF_INITIAL_RECOGNIZERS = 1
  MAX_RECOGNIZERS = 5
  LIFE_CYCLE_IN_SECONDS = 3 * 60
  MAX_OPEN_TIME_IN_SECONDS = 30
  
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
    elsif (active_recognizers.size) < MAX_RECOGNIZERS
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
    pool[:idle] << recognizer if (pool[:idle].size < MAX_IDLE_RECOGNIZERS)
  end
  
  def self.clean_pool
    pool.each_pair do |key, session|
      if key != :idle
	if (Time.now - session.created_at) >  LIFE_CYCLE_IN_SECONDS
	  pool.delete(key)
	elsif !session.closed? && (Time.now - session.created_at) >  MAX_OPEN_TIME_IN_SECONDS
	  session.close!
	  session.system_message = "Session time limit exceeded"
	end
      end
    end
  end
end