# -*- coding: utf-8 -*-

#This module contains any exceptions common to server and client
#libraries.
module OpenRubyRMK::Common::Errors

  # Superclass of every exception specific to the OpenRubyRMK.
  class OpenRubyRMKError < StandardError
  end

  # Raised if you fed invalid or logically wrong XML
  # to the Transformer.
  class MalformedCommand < OpenRubyRMKError
  end

  # Raised when authentication failed.
  class AuthenticationError < OpenRubyRMKError
  end

  # Raised when an unknown parameter in a request/response/notification
  # is encountered.
  class UnknownParameter < OpenRubyRMKError

    #The name of the parameter that was unknown.
    attr_reader :name

    #If the offending action was a request, the corresponding
    #Request instance.
    attr_reader :request

    #If the offending action was a response, the corresponding
    #Response instance.
    attr_reader :response

    #If the offending action was a notification, the
    #corresponding Notification instance.
    attr_reader :notification

    #Creates a new exception of this type.
    #==Parameters
    #[action_instance] The offending Request, Response or
    #                  Notification instance.
    #[name]            The name of the unknown parameter.
    #[msg]             ("Unknown parameter `x' for <y>")
    #                  The error message.
    #==Raises
    #[TypeError] If +action_instance+ was something other than
    #            a Request, Response, or Notification instance.
    #==Return value
    #A new exception of this type.
    def initialize(action_instance, name, msg = "Unknown parameter `#{name}' for #{action_instance.inspect}!")
      super(msg)
      @name = name
      case action_instance
      when OpenRubyRMK::Common::Request      then @request      = action_instance
      when OpenRubyRMK::Common::Response     then @response     = action_instance
      when OpenRubyRMK::Common::Notification then @notification = action_instance
      else
        raise(TypeError, "Don't know how to handle unknown parameters for this: #{action_instance}")
      end
    end

  end

end
