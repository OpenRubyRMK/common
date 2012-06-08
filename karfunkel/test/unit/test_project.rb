# -*- coding: utf-8 -*-
require "test/unit"
require "tempfile"
require "turn/autorun"
require "zlib"
require "archive/tar/minitar"
require "tiled_tmx"

require_relative "../../lib/open_ruby_rmk/karfunkel"
require_relative "../../plugins/base/project"
require_relative "../../plugins/base/map"

# Ignore any calls to the server. This is a unit test, and
# doesn’t need the server. Merely this is used to ignore
# calls to the server’s logger which isn’t set up as
# Karfunkel isn’t running.
class OpenRubyRMK::Karfunkel
  THE_INSTANCE = Object.new
  THE_INSTANCE.instance_eval do
    def method_missing(*) # :nodoc:
      self
    end
  end
end

class ProjectTest < Test::Unit::TestCase
  include OpenRubyRMK
  include OpenRubyRMK::Karfunkel::Plugin::Base

  def assert_dir(path, msg = nil)
    assert(File.directory?(path), msg || "Not a directory: #{path}")
  end

  def assert_file(path, msg = nil)
    assert(File.file?(path), msg || "Not a file: #{path}")
  end

  def refute_exists(path, msg = nil)
    assert(!File.exists?(path), msg || "File exists: #{path}")
  end

  def setup
    @tmpdir = Pathname.new(Dir.mktmpdir)
  end

  def teardown
    @tmpdir.rmtree if @tmpdir.directory? # Migh be removed from a test
  end

  def test_paths
    pr = Project.new(@tmpdir)
    assert_equal(@tmpdir, pr.paths.root)
    assert_equal(@tmpdir + "bin" + "#{@tmpdir.basename}.rmk", pr.paths.rmk_file)
    assert_equal(@tmpdir + "data", pr.paths.data_dir)
    assert_equal(@tmpdir + "data" + "maps", pr.paths.maps_dir)
    assert_equal(@tmpdir + "data" + "maps" + "maps.xml", pr.paths.maps_file)
  end

  def test_creation
    pr = Project.new(@tmpdir)
    assert_file(@tmpdir + "bin" + "#{@tmpdir.basename}.rmk")
    assert_dir(@tmpdir + "data")
    assert_dir(@tmpdir + "data" + "maps")
    assert_file(@tmpdir + "data" + "maps" + "maps.xml")
    assert_equal(Karfunkel::VERSION, pr.config["open_ruby_rmk"]["version"])
    assert(pr.config["project"]["name"], "Project has no full name!")
    assert_equal("0.0.1", pr.config["project"]["version"])
  end

  def test_loading
    pr = Project.new(@tmpdir)
    pr.root_maps << Map.new(pr, "foo-map")
    pr.save

    pr = Project.load(@tmpdir)
    assert_equal(@tmpdir, pr.paths.root)
    assert_equal(1, pr.root_maps.count)
    assert_equal("foo-map", pr.root_maps.first.name)
  end

  def test_deletion
    pr = Project.new(@tmpdir)
    pr.delete!
    refute_exists(@tmpdir)
  end

  def test_saving
    pr = Project.new(@tmpdir)
    assert_equal(0, Nokogiri::XML(File.read(@tmpdir + "data" + "maps" + "maps.xml")).root.xpath("map").count)
    pr.root_maps << Map.new(pr)
    pr.save
    assert_file(@tmpdir + "data" + "maps" + "0001.tmx")
    assert_equal(1, Nokogiri::XML(File.read(@tmpdir + "data" + "maps" + "maps.xml")).root.xpath("map").count)
  end

end
