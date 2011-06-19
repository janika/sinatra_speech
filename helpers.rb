helpers do
  
  def render_error(message)
    if response_type == "application/json"
      error_to_json(message)
    else
      error_to_xml(message)
    end
  end
  
  def error_to_json(message)
    {:error => {:message => message}}.to_json
  end
  
  def error_to_xml(message)
    builder do |xml|
      xml.instruct! :xml, :version => '1.0'
      xml.error do
        xml.message message
      end
    end
  end
  
  def set_headers
    headers "Content-Type"=>"text/xml;charset=utf-8;"
  end
  
  def render_with_type(session)
    if response_type == "application/json"
      session.to_json
    else
      session.to_xml
    end
  end
  
  def response_type
    env['HTTP_ACCEPT']
  end
  
  def work_with_session(close = false)
    begin
      session = RecognizerPool.find_by_session_id(params[:id])
      if session
        if session.closed?
          render_error("Session with id #{params[:id]} is already closed")
        else
          close ? session.close! : session.recognize(request.body)
          render_with_type(session)
        end
      else
        render_error("Session with id #{params[:id]} not found")
      end
    rescue Exception => e
      render_error(e.message)
    end
  end
  
end