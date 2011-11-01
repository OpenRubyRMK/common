# -*- coding: utf-8 -*-

OpenRubyRMK::Karfunkel.define_request :Ping do
  
  def execute(pars)
    #If Karfunkel gets a PING request, we just answer it as OK and
    #are done with it.
    answer :ok
  end
  
  def process_response(resp)
    #Nothing is necessary here, because a client’s availability status
    #is set automatically if it sends a reponse. I just place the
    #method here, because without it we would get a NotImplementedError
    #exception.
  end
  
end