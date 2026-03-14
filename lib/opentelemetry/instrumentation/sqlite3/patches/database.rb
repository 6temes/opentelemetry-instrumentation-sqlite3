# frozen_string_literal: true

require "opentelemetry-helpers-sql-processor"

module OpenTelemetry
  module Instrumentation
    module SQLite3
      module Patches
        # Module to prepend to SQLite3::Database for instrumentation
        module Database
          def execute(sql, bind_vars = [], &block)
            trace(sql) { super }
          end

          def execute2(sql, *bind_vars, &block)
            trace(sql) { super }
          end

          def execute_batch(sql, bind_vars = [])
            trace(sql) { super }
          end

          def execute_batch2(sql, &block)
            trace(sql) { super }
          end

          def query(sql, bind_vars = [], &block)
            trace(sql) { super }
          end

          private

          def trace(sql)
            tracer.in_span(
              span_name(sql),
              attributes: span_attributes(sql),
              kind: :client,
              record_exception: config[:record_exception]
            ) { yield }
          end

          def span_name(sql)
            [extract_operation(sql), database_name].compact.join(" ").then { _1.empty? ? "SQL" : _1 }
          end

          def span_attributes(sql)
            attributes = {
              "db.system" => "sqlite"
            }

            db = database_name
            attributes["db.name"] = db if db

            case config[:db_statement]
            when :obfuscate
              attributes["db.statement"] =
                OpenTelemetry::Helpers::SqlProcessor.obfuscate_sql(sql, obfuscation_limit: config[:obfuscation_limit], adapter: :default)
            when :include
              attributes["db.statement"] = sql
            end

            attributes
          end

          def extract_operation(sql)
            sql.strip[/\A(\w+)/, 1]&.upcase
          end

          def database_name
            return @_database_name if defined?(@_database_name)

            f = filename.to_s
            @_database_name = if f.empty? || f == ":memory:"
              nil
            else
              File.basename(f)
            end
          end

          def tracer
            @_tracer ||= SQLite3::Instrumentation.instance.tracer
          end

          def config
            @_config ||= SQLite3::Instrumentation.instance.config
          end
        end
      end
    end
  end
end
