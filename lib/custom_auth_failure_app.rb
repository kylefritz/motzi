class CustomAuthFailureApp < Devise::FailureApp
  def respond
    if request.content_type == 'application/json'
      json_failure_response
    else
      super
    end
  end

  def json_failure_response
    puts "making a json_failure_response"
    self.status = 401
    self.content_type = 'application/json'
    self.response_body = { error: 'Unauthorized to make that request' }.to_json
  end
end
