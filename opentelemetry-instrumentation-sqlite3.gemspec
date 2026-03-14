# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "opentelemetry/instrumentation/sqlite3/version"

Gem::Specification.new do |spec|
  spec.name        = "opentelemetry-instrumentation-sqlite3"
  spec.version     = OpenTelemetry::Instrumentation::SQLite3::VERSION
  spec.authors     = ["Daniel Lopez"]
  spec.email       = ["daniel@6temes.cat"]

  spec.summary     = "SQLite3 instrumentation for the OpenTelemetry framework"
  spec.description = "Adds auto instrumentation for the sqlite3 gem, including SQL statement capture with obfuscation"
  spec.homepage    = "https://github.com/6temes/opentelemetry-instrumentation-sqlite3"
  spec.license     = "Apache-2.0"

  spec.files = Dir.glob("lib/**/*.rb") +
               Dir.glob("*.md") +
               ["LICENSE"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "opentelemetry-helpers-sql"
  spec.add_dependency "opentelemetry-helpers-sql-processor"
  spec.add_dependency "opentelemetry-instrumentation-base", "~> 0.25"
  spec.add_dependency "opentelemetry-semantic_conventions", ">= 1.8.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3/issues",
    "changelog_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3"
  }
end
