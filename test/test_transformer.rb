# -*- coding: utf-8 -*-
require_relative "helpers"

class TransformerTest < Test::Unit::TestCase
  include OpenRubyRMK::Common

  #Directory to load sample data from.
  DATA_DIR = Pathname.new(__FILE__).dirname.expand_path + "data"

  def setup
    @transformer = Transformer.new
  end

  def test_parse_normal_requests
    cmd = @transformer.parse!(xml("1.xml"))
    req = cmd.requests.first
    assert_equal(11, cmd.from_id)
    assert_equal(1, cmd.requests.count)
    assert_equal("foo", req.type)
    assert_equal(3, req.id)
    assert_equal("Parameter 1", req["par1"])
    assert_equal("Parameter 2", req["par2"])
    assert(req.running?, "Request was not running!")

    cmd = @transformer.parse!(xml("2.xml"))
    assert_equal(2, cmd.requests.count)
  end

  def test_parse_hello_request
    cmd = @transformer.parse!(xml("hello1.xml"))
    assert_equal(-1, cmd.from_id)
    assert_equal(0, cmd.requests.first.id)

    assert_raises(Errors::MalformedCommand) do
      @transformer.parse!(xml("hello2.xml"))
    end
  end

  def test_parse_notifications
    cmd = @transformer.parse!(xml("6.xml"))
    assert_equal(1, cmd.notifications.count)
    note = cmd.notifications.first
    assert_equal("foo", note.type)
    assert_equal("Parameter 1", note["par1"])
    assert_equal("Parameter 2", note["par2"])
  end

  def test_convert_normal_requests
    cmd = Command.new(11)
    req = Request.new(3, "foo")
    req["par1"] = "Parameter 1"
    req["par2"] = "Parameter 2"
    cmd.requests << req
    assert_equal(xml("1.xml"), @transformer.convert!(cmd))

    cmd = Command.new(11)
    cmd.requests << Request.new(77, "foo")
    cmd.requests << Request.new(78, "foo")
    assert_equal(xml("2.xml"), @transformer.convert!(cmd))
  end

  def test_convert_hello_request
    cmd = Command.new(-1) # Hello isn’t allowed to sent an ID
    req = Request.new(0, "Hello")
    req["os"] = "Linux"
    cmd.requests << req
    assert_equal(xml("hello1.xml"), @transformer.convert!(cmd))

    cmd = Command.new(12)
    req = Request.new(0, "Hello") # Invalid due to sender ID given to command!
    cmd.requests << req
    assert(!cmd.valid?, "Treated malformed command as valid")
    assert_raises(Errors::MalformedCommand) do
      @transformer.convert!(cmd)
    end
  end

  def test_convert_notifications
    cmd  = Command.new(11)
    note = Notification.new(3, "foo")
    note["par1"] = "Parameter 1"
    note["par2"] = "Parameter 2"
    cmd << note
    assert_equal(xml("6.xml"), @transformer.convert!(cmd))
  end

  def test_parse_responses
    cmd = Command.new(11)
    cmd.requests << Request.new(1, "foo")
    cmd.requests << Request.new(2, "foo")
    req = Request.new(3, "foo") # We’re going to need this request later
    cmd.requests << req

    # Make the transformer remember the unanswered request
    # (immediately after this the XML would be sent over
    # the wire)
    @transformer.convert!(cmd)

    # Test whether the requests have been correctly remembered
    assert_equal(3, @transformer.waiting_requests.count)

    # Now simulate the response
    cmd2 = @transformer.parse!(xml("3.xml"))

    # Test if the requests have been correctly processed
    assert_equal(2, @transformer.waiting_requests.count)
    assert_equal(2, cmd2.responses.count)
    assert(cmd2.responses.any?{|r| r.request == req}, "Expected response not found!")
    assert_equal(1, req.responses.count)
    assert_equal(cmd2.responses.find{|r| r.request == req}, req.responses.first)
  end

  def test_convert_responses
    # Simulate the request
    cmd = @transformer.parse!(xml("4.xml"))
    req = cmd.requests.first

    # Now construct the response
    cmd2 = Command.new(123)
    cmd2 << Response.new(12, "ok", req)
    assert_equal(xml("5.xml"), @transformer.convert!(cmd2))
  end

  def test_round_trip
    cmd = Command.new(11)
    cmd.requests << Request.new(3, "foo")

    str     = @transformer.convert!(cmd)
    new_cmd = @transformer.parse!(str)
    new_str = @transformer.convert!(new_cmd)

    assert_equal(cmd, new_cmd)
    assert_equal(str, new_str)
  end

  private

  def xml(name)
    DATA_DIR.join(name).read
  end

end
