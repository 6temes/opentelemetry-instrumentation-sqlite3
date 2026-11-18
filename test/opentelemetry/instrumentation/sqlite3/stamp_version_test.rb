# frozen_string_literal: true

require "test_helper"
require "open3"
require "tmpdir"

class StampVersionTest < Minitest::Test
  ROOT = File.expand_path("../../../..", __dir__)
  SCRIPT = File.join(ROOT, "bin/stamp-version")
  VERSION_FILE = File.join(ROOT, "lib/opentelemetry/instrumentation/sqlite3/version.rb")

  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "version.rb")
    FileUtils.cp(VERSION_FILE, @path)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def test_stamps_the_tag_version_into_the_constant
    _, status = stamp("1.2.3")

    assert status.success?
    assert_equal "1.2.3", loaded_version
  end

  def test_rejects_versions_that_would_not_build_as_named
    original = File.read(@path)

    [ "abc", "", "1.2.3-rc1" ].each do |version|
      _, status = stamp(version)

      refute status.success?, "expected #{version.inspect} to be rejected"
      assert_equal original, File.read(@path)
    end
  end

  def test_rejects_a_file_without_a_version_literal
    File.write(@path, "module Foo\nend\n")

    _, status = stamp("1.2.3")

    refute status.success?
    assert_equal "module Foo\nend\n", File.read(@path)
  end

  def test_rejects_a_placeholder_followed_by_a_second_version_assignment
    placeholder = File.read(VERSION_FILE)

    [ "=begin\n      VERSION = \"9.9.9\"\n=end\n", "      VERSION = \"9.9.9\".freeze\n" ].each do |second|
      shadowed = placeholder.sub("    end\n") { "#{second}    end\n" }
      File.write(@path, shadowed)

      _, status = stamp("1.2.3")

      refute status.success?, "expected a stamp shadowed by #{second.inspect} to fail"
      assert_equal shadowed.b, File.binread(@path)
    end
  end

  private
    def stamp(version)
      unbundled_ruby(SCRIPT, version, @path)
    end

    # Read back in a subprocess so the test process never redefines the real constant.
    def loaded_version
      out, status = unbundled_ruby("-e", "load ARGV[0]; print OpenTelemetry::Instrumentation::SQLite3::VERSION", @path)
      assert status.success?, out
      out
    end

    # Under `bundle exec` a child Ruby would load bundler/setup, and with it the
    # gemspec and the real version.rb. The release job runs without bundler too.
    def unbundled_ruby(*args)
      Bundler.with_unbundled_env { Open3.capture2e(RbConfig.ruby, *args) }
    end
end
