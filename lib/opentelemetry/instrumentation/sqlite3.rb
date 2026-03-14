# frozen_string_literal: true

require "opentelemetry"
require "opentelemetry-instrumentation-base"
require "opentelemetry-helpers-sql"

module OpenTelemetry
  module Instrumentation
    # Contains the OpenTelemetry instrumentation for the SQLite3 gem
    module SQLite3
    end
  end
end

require_relative "sqlite3/instrumentation"
require_relative "sqlite3/version"
