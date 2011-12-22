gem "test-unit"
require "test/unit"
require "pathname"

require_relative "../lib/common"

class ParserTest < Test::Unit::TestCase

  DATA_DIR          = Pathname.new(__FILE__).dirname.expand_path + "data"
  
  # Called once at test beginning
  def self.startup
    @@transformer = Transformer.new
  end

  def test_normal_requests
    cmd = @@transformer.parse!(xml("1.xml"))
    req = cmd.requests.first
    assert_equal(11, cmd.from_id)
    assert_equal(1, cmd.requests.count)
    assert_equal("foo", req.type)
    assert_equal(3, req.id)
    assert_equal("Parameter 1", req["par1"])
    assert_equal("Parameter 2", req["par2"])

    cmd = @@transformer.parse!(xml("2.xml"))
    assert_equal(2, cmd.requests.count)
  end

  private

  def xml(name)
    DATA_DIR.join(name).read
  end

end
