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
    FileUtils.remove_entry @dir
  end

  def test_placeholder_satisfies_the_requirement_bundler_gives_a_git_source
    assert_operator Gem::Version.new(OpenTelemetry::Instrumentation::SQLite3::VERSION), :>=, Gem::Version.new("0")
  end

  def test_stamps_the_version_into_a_copy_of_the_real_version_rb
    _, status = stamp "1.2.3"

    assert status.success?
    assert_equal "1.2.3", loaded_version
  end

  def test_rejects_a_version_that_is_not_canonical_leaving_the_file_unchanged
    original = File.read(@path)

    [ "abc", "", "1.2.3-rc1" ].each do |version|
      stderr, status = stamp version

      refute status.success?, "accepted #{version.inspect}"
      assert_match "is not a canonical gem version", stderr
      assert_equal original, File.read(@path)
    end
  end

  def test_rejects_a_file_without_a_version_literal_leaving_it_unchanged
    File.write @path, "module Foo\nend\n"

    stderr, status = stamp "1.2.3"

    refute status.success?
    assert_match "expected one VERSION literal", stderr
    assert_equal "module Foo\nend\n", File.read(@path)
  end

  def test_rejects_a_file_that_does_not_load_as_the_stamped_version_leaving_it_unchanged
    [
      ->(placeholder) { "=begin\n#{placeholder}=end\n" },
      ->(placeholder) { "#{placeholder}VERSION = \"9.9.9\" # release version\n" },
      # Prints the tag's head first, so a check that read the child's output would pass.
      ->(placeholder) { "#{placeholder}print \"1.\"\nVERSION = \"2.3\".freeze\n" }
    ].each do |rewrite|
      source = File.read(VERSION_FILE).sub(/^\s*VERSION = .*\n/) { rewrite.(it) }
      File.write @path, source

      stderr, status = stamp "1.2.3"

      refute status.success?, "stamped #{source.inspect}"
      assert_match "does not load as", stderr
      assert_equal source, File.read(@path)
    end
  end

  private
    def stamp(version)
      _, stderr, status = Open3.capture3(RbConfig.ruby, SCRIPT, version, @path)
      [ stderr, status ]
    end

    # A child process without bundler, so this suite's own constant is never redefined.
    def loaded_version
      stdout, status = Open3.capture2({ "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil }, RbConfig.ruby, "-e", "load ARGV[0]; print OpenTelemetry::Instrumentation::SQLite3::VERSION", @path)
      assert status.success?
      stdout
    end
end
