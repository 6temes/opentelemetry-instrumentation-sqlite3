# frozen_string_literal: true

require "test_helper"

class InstrumentationTest < Minitest::Test
  def setup
    EXPORTER.reset
    @db = ::SQLite3::Database.new(":memory:")
    @db.execute("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)")
    EXPORTER.reset # Clear the CREATE TABLE span
  end

  def teardown
    @db.close
  end

  def test_execute_creates_span
    @db.execute("INSERT INTO users (name, email) VALUES (?, ?)", [ "Alice", "alice@example.com" ])

    spans = EXPORTER.finished_spans
    assert_equal 1, spans.length

    span = spans.first
    assert_equal "INSERT", span.name
    assert_equal :client, span.kind
    assert_equal "sqlite", span.attributes["db.system"]
  end

  def test_execute_obfuscates_sql_by_default
    @db.execute("INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')")

    span = EXPORTER.finished_spans.first
    statement = span.attributes["db.statement"]
    assert_includes statement, "INSERT INTO users"
    refute_includes statement, "Alice"
    refute_includes statement, "alice@example.com"
  end

  def test_query_creates_span
    @db.execute("INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')")
    EXPORTER.reset

    @db.query("SELECT * FROM users WHERE name = ?", [ "Alice" ])

    spans = EXPORTER.finished_spans
    assert_equal 1, spans.length
    assert_equal "SELECT", spans.first.name
  end

  def test_execute_batch_creates_span
    sql = <<~SQL
      INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');
      INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com');
    SQL
    @db.execute_batch(sql)

    spans = EXPORTER.finished_spans
    assert_equal 1, spans.length
    assert_equal "INSERT", spans.first.name
  end

  def test_execute_batch2_creates_span
    sql = <<~SQL
      INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com');
      INSERT INTO users (name, email) VALUES ('Bob', 'bob@example.com');
    SQL
    @db.execute_batch2(sql)

    spans = EXPORTER.finished_spans
    assert_equal 1, spans.length
    assert_equal "INSERT", spans.first.name
  end

  def test_execute2_creates_span
    @db.execute("INSERT INTO users (name, email) VALUES ('Alice', 'alice@example.com')")
    EXPORTER.reset

    @db.execute2("SELECT * FROM users")

    spans = EXPORTER.finished_spans
    assert_equal 1, spans.length
    assert_equal "SELECT", spans.first.name
  end

  def test_span_includes_db_system
    @db.execute("SELECT 1")

    span = EXPORTER.finished_spans.first
    assert_equal "sqlite", span.attributes["db.system"]
  end

  def test_span_includes_db_name_for_file_database
    Dir.mktmpdir do |dir|
      path = File.join(dir, "test.sqlite3")
      db = ::SQLite3::Database.new(path)
      EXPORTER.reset
      db.execute("SELECT 1")
      db.close

      span = EXPORTER.finished_spans.last
      assert_equal "test.sqlite3", span.attributes["db.name"]
    end
  end

  def test_span_omits_db_name_for_memory_database
    @db.execute("SELECT 1")

    span = EXPORTER.finished_spans.first
    refute span.attributes.key?("db.name")
  end

  def test_records_exceptions
    assert_raises(::SQLite3::SQLException) do
      @db.execute("SELECT * FROM nonexistent_table")
    end

    span = EXPORTER.finished_spans.first
    assert_equal OpenTelemetry::Trace::Status::ERROR, span.status.code

    events = span.events
    assert_equal 1, events.length
    assert_equal "exception", events.first.name
  end

  def test_span_name_includes_operation
    @db.execute("SELECT * FROM users")

    span = EXPORTER.finished_spans.first
    assert_equal "SELECT", span.name
  end

  def test_span_includes_db_operation
    @db.execute("SELECT * FROM users")

    span = EXPORTER.finished_spans.first
    assert_equal "SELECT", span.attributes["db.operation"]
  end
end
