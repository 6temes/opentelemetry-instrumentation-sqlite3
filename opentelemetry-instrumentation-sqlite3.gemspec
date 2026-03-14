require_relative "lib/opentelemetry/instrumentation/sqlite3/version"

Gem::Specification.new do |spec|
  spec.name = "opentelemetry-instrumentation-sqlite3"
  spec.version = OpenTelemetry::Instrumentation::SQLite3::VERSION
  spec.authors = [ "Daniel Lopez Prat" ]
  spec.email = [ "daniel@6temes.cat" ]
  spec.homepage = "https://github.com/6temes/opentelemetry-instrumentation-sqlite3"
  spec.summary = "SQLite3 instrumentation for the OpenTelemetry framework"
  spec.description = "Adds auto instrumentation for the sqlite3 gem, including SQL statement capture with obfuscation"
  spec.license = "Apache-2.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3/issues",
    "changelog_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3/releases",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/6temes/opentelemetry-instrumentation-sqlite3"
  }

  spec.required_ruby_version = ">= 4.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "cgi"
  spec.add_dependency "opentelemetry-helpers-sql"
  spec.add_dependency "opentelemetry-helpers-sql-processor"
  spec.add_dependency "opentelemetry-instrumentation-base", "~> 0.25"
  spec.add_dependency "sqlite3", ">= 2.0"
end
