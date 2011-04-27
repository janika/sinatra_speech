module RecognizerPool
  MAX_IDLE_RECOGNIZERS = 2
  NUMBER_OF_INITIAL_RECOGNIZERS = 1
  MAX_RECOGNIZERS = 5
  
  def self.pool
    $recognizer_pool
  end
  
  def self.get_for_session(session_id)
    recognizer = pool.fetch(session_id)
    if !recognizer.nil?
      return recognizer
    else
      raise "Recognizer not found"   
    end
  end
  
  def self.add_new_to_active_pool(session)
    recognizer = get_recognizer
    if !recognizer.nil?
      pool[session.id] = recognizer
    else
      raise "No free recognizers"
    end
  end
  
  def self.recognize_for_session(session, data, end_session = false)
    recognizer = RecognizerPool.get_for_session(session.id)
    if recognizer.nil?
      raise "Recognizer for session #{session.id} not found."
    elsif end_session
      recognizer.end_feed(session)
    else
      recognizer.work_with_data(data, session)
    end
  end
  
  def self.get_recognizer
    if pool[:idle].size > 0
      pool[:idle].pop
    elsif (pool.size - 1) < MAX_RECOGNIZERS
      Recognizer.new
    end
  end
  
  def self.collect_idle
    pool.each do |session_id, recognizer|
      if session_id != :idle
        recognizer_session = SessionPool.find_by_id(session_id)
        if recognizer_session.closed?
          pool[:idle] << recognizer if (pool[:idle].size < MAX_IDLE_RECOGNIZERS)
          pool.delete(session_id)
        end
      end
    end
  end
end