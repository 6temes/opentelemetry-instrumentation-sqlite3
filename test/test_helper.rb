# frozen_string_literal: true

require "minitest/autorun"
require "sqlite3"
require "opentelemetry-sdk"
require "opentelemetry-instrumentation-sqlite3"

EXPORTER = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new

OpenTelemetry::SDK.configure do |c|
  c.add_span_processor OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(EXPORTER)
  c.use "OpenTelemetry::Instrumentation::SQLite3"
end
