# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  def setup
    EXPORTER.reset
    @db = ::SQLite3::Database.new(":memory:")
    @db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
    EXPORTER.reset
  end

  def teardown
    @db.close
  end

  def test_include_shows_raw_sql
    with_config(db_statement: :include) do
      @db.execute("INSERT INTO users (name) VALUES ('Alice')")

      span = EXPORTER.finished_spans.first
      assert_includes span.attributes["db.statement"], "Alice"
    end
  end

  def test_omit_excludes_sql
    with_config(db_statement: :omit) do
      @db.execute("INSERT INTO users (name) VALUES ('Alice')")

      span = EXPORTER.finished_spans.first
      refute span.attributes.key?("db.statement")
    end
  end

  def test_obfuscate_hides_values
    with_config(db_statement: :obfuscate) do
      @db.execute("INSERT INTO users (name) VALUES ('Alice')")

      span = EXPORTER.finished_spans.first
      statement = span.attributes["db.statement"]
      assert_includes statement, "INSERT INTO users"
      refute_includes statement, "Alice"
    end
  end

  def test_record_exception_false_suppresses_exception_events
    with_config(record_exception: false) do
      assert_raises(::SQLite3::SQLException) do
        @db.execute("SELECT * FROM nonexistent_table")
      end

      span = EXPORTER.finished_spans.first
      assert_equal OpenTelemetry::Trace::Status::ERROR, span.status.code
      assert_nil span.events
    end
  end

  private

  def with_config(**overrides)
    instance = OpenTelemetry::Instrumentation::SQLite3::Instrumentation.instance
    original = instance.config.dup
    overrides.each { |k, v| instance.config[k] = v }
    yield
  ensure
    original.each { |k, v| instance.config[k] = v }
  end
end
