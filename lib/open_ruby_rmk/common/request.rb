# -*- coding: utf-8 -*-

module OpenRubyRMK::Common

  #A Request is the part of a Command that advertises Karfunkel to take
  #action. It consists of a unique ID, a request body containing the
  #parameters that modify a request’s meaning slightly and a type that
  #defines the parameters that can be passed along with this request.
  #
  #As it’s part of a Command instance, a request’s external representation
  #is a XML structure. The tag is named REQUEST and parameters may be
  #passed via a parameter tag inside the REQUEST tag.
  #
  #After you passed a request to your local Transformer instance,
  #the transformer remembers the request as "unanswered" until you
  #receive either a OK or FINISHED response from the other side of
  #the connection. Whenever you receive a response answering your
  #specific request (this includes *all* kinds of responses, not just
  #FINISHED and OK), the response is added to your waiting request’s
  #+responses+ array which allows you to easily access all responses
  #that happen. However, after receiving either OK or FINISHED, no more
  #responses will be added to the request.
  #
  #Request, Response and Notification instances all have "parameters", i.e. any
  #information sent with the respective action XML node. This
  #information can be set and read via the #[]= and #[] methods,
  #respectively. By default, when accessing an action’s parameters
  #by use of #[], all parameters are treated as being required.
  #This means that if you access a parameter +foo+ from a Request
  #instance built from the XML a client sent to you, but the XML
  #did not include a +foo+ tag, the #[] method will raise an
  #UnknownParameter exception. If this is not what you desire, you
  #can mark certain parameters as being _optional_ by means of
  #the #add_default_value method. If you do so and the above
  #case happens, instead of raising an exception the #[] method will
  #return a default value you specified when calling #add_default_value.
  #It is not possible to mark a parameter as optional in the XML
  #representation, because that wouldn’t make any sense at all (it’s
  #part of the _processing_ of the XML).
  #
  #== Request types
  #This basic class doesn’t know anything about the actual request
  #types beyond the +type+ attribute. This means you can use it to
  #construct every possible kind of requests (even invalid ones),
  #but this doesn’t automatically mean that Karfunkel understands
  #your home-made request types. Have a look at Karfunkel’s documentation
  #in order to find out how to make him aware of new kinds of requests.
  #
  #== Sample XML
  #=== With parameters
  #  <request type="foo" id="3">
  #    <par1>Parameter 1</par1>
  #    <par2>Parameter 2</par>
  #  </request>
  #=== Without parameters
  #  <request type="foo" id="99"/>
  class Request
    
    #The (hopefully) unique request ID.
    attr_reader :id
    #A request’s type as a *string*. XML doesn’t know
    #about symbols, hence no Symbol instance here.
    attr_reader :type
    #An array of Response instances that refer to this
    #request.
    attr_reader :responses
    #The parameters passed along with this request.
    #As they’re directly derived from the XML code,
    #both keys and values of this hash are strings.
    attr_accessor :parameters
    #The default values for optional parameters. A hash
    #of form:
    #  {"optional_parameter_name" => "default value"}
    #Note that for symmetry with #parameters, both keys
    #and values should be strings here as well.
    attr_accessor :default_parameter_values

    #Creates a new Request instance.
    #==Parameters
    #[id]   The ID to assign to this request. This should be
    #       unique as it is used to map responses to their
    #       corresponding requests, so be careful when
    #       choosing this.
    #[type] The request’s type. You can pass anything you
    #       like, but Karfunkel only understands a limited
    #       number of requests (see also this class’
    #       introductory text). This will be autoconverted
    #       to a string for XML by calling #to_s.
    #==Return value
    #A new Request instance.
    #==Example
    #  cmd = Command.new(1)
    #  cmd << Request.new(1, "Foo")
    #  cmd << Request.new(3, "Bar")
    def initialize(id, type)
      @id         = id
      @type       = type.to_s
      @parameters = {}
      @default_parameter_values = {}
      @responses  = []
    end

    #Mark a parameter as optional, i.e. cause #[] to not
    #raise if the requested parameter doesn’t exist.
    #==Parameters
    #[name] The name of the parameter, either symbol or string.
    #       Automatically converted to a string.
    #[default_value] ("") A default value #[] shall return if
    #                the parameter is missing. Automatically
    #                converted to a string if necessary.
    def add_default_value(name, default_value = "")
      @default_parameter_values[name.to_s] = default_value.to_s
    end

    #Grabs the value of the specified parameter.
    #==Parameter
    #[par] The name of the parameter. This will
    #      be automatically converted to a string
    #      by calling #to_s.
    #==Return value
    #The value of the parameter as a string as it
    #comes directly from the XML. If the parameter
    #doesn’t exist, returns nil.
    #==Example
    #  req = Request.new(1, "Foo")
    #  req["foo"] = "bar"
    #  req[:abc]  = 33
    #   
    #  req["foo"] #=> "bar"
    #  req[:foo]  #=> "bar"
    #  req[:abc]  #=> "33"
    #  req["abc"] #=> "33"
    def [](par)
      par = par.to_s
      if @parameters.has_key?(par)
        @parameters[par]
      elsif @default_parameter_values.has_key?(par)
        @default_parameter_values[par]
      else
        raise(Errors::UnknownParameter.new(self, par))
      end
    end

    #Sets the specified parameter. Note no check happens whether
    #or not what you specify is valid in the context of the
    #request’s type.
    #==Parameters
    #[par]   The name of the parameter you want to set. Autoconverted
    #        to a string by calling #to_s.
    #[value] The value of the parameter you want to set. Autoconverted
    #        to a string by calling #to_s.
    #==Return value
    #Exactly +value+ as this is enforced by the Ruby interpreter
    #itself.
    #==Example
    #  req = Request.new(1, "Foo")
    #  req["foo"] = "bar"
    #  req[:abc]  = 33
    #   
    #  req["foo"] #=> "bar"
    #  req[:foo]  #=> "bar"
    #  req[:abc]  #=> "33"
    #  req["abc"] #=> "33"
    def []=(par, value)
      @parameters[par.to_s] = value.to_s
    end

    #call-seq:
    #  eql?(other)   → bool
    #  self == other → bool
    #
    #Checks if two requests are equal to each other. Two
    #requests are considered equal if their ID and type are the same;
    #as the aspect of clients sending and receiving requests
    #isn’t available in this context (only in Command instances)
    #this isn’t checked here.
    def eql?(other)
      return nil unless other.respond_to?(:id) and other.respond_to?(:type)
      @id == other.id && @type == other.type
    end
    alias == eql?

    #Checks wheather this request was already answered with a n OK or
    #FINISHED response. A freshly created request of course is considered
    #running.
    #==Return value
    #Either true or false.
    #==Example
    #  req.running? #=> true
    #  trans.parse!(some_xml) # Contains a response to this request
    #  req.running? #=> false
    #  # By-reference magic! ;-)
    def running?
      @responses.none?{|resp| resp.status == "ok" or resp.status == "finished"}
    end

    #Human-readable description of form:
    #  <OpenRubyRMK::Common::Request <TYPE> (<id>)>
    def inspect
      "<#{self.class} #{@type.upcase} (#@id)>"
    end

  end

end
