# frozen_string_literal: true

module OpenTelemetry
  module Instrumentation
    module SQLite3
      # The Instrumentation class contains logic to detect and install the SQLite3 instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_dependencies
          patch_client
        end

        present do
          defined?(::SQLite3::Database)
        end

        compatible do
          Gem::Requirement.create(">= 2.0", "< 3.0").satisfied_by?(Gem::Version.new(::SQLite3::VERSION))
        end

        option :db_statement, default: :obfuscate, validate: %I[omit include obfuscate]
        option :obfuscation_limit, default: 2000, validate: :integer
        option :record_exception, default: true, validate: :boolean

        private

        def require_dependencies
          require_relative "patches/database"
        end

        def patch_client
          ::SQLite3::Database.prepend(Patches::Database)
        end
      end
    end
  end
end
