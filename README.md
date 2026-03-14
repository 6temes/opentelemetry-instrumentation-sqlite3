<div align="center">
  <h1>OpenTelemetry SQLite3 Instrumentation</h1>

  <h3>Auto-instrumentation for the Ruby sqlite3 gem</h3>

  <div>
    <a href="https://github.com/6temes/opentelemetry-instrumentation-sqlite3/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-Apache--2.0-green"/></a>
    <a href="https://www.ruby-lang.org/"><img alt="Ruby" src="https://img.shields.io/badge/ruby-3.1+-red.svg"/></a>
    <a href="https://opentelemetry.io/"><img alt="OpenTelemetry" src="https://img.shields.io/badge/OpenTelemetry-enabled-blue"/></a>
  </div>

  <p>
    <a href="#installation">Installation</a>
    ◆ <a href="#usage">Usage</a>
    ◆ <a href="#configuration">Configuration</a>
    ◆ <a href="#semantic-conventions">Semantic Conventions</a>
  </p>
</div>

---

Wraps `SQLite3::Database` query methods with OpenTelemetry spans, capturing SQL statements with configurable obfuscation. Fills the gap in the OpenTelemetry Ruby ecosystem where adapter instrumentations exist for [PG](https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/pg), [Mysql2](https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/mysql2), and [Trilogy](https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation/trilogy), but not for SQLite3.

## Installation

Add to your Gemfile:

```ruby
gem "opentelemetry-instrumentation-sqlite3", github: "6temes/opentelemetry-instrumentation-sqlite3"
```

## Usage

### With `use_all` (recommended)

If you already use `opentelemetry-instrumentation-all`, the SQLite3 instrumentation is picked up automatically:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use_all
end
```

### Standalone

```ruby
require "opentelemetry/sdk"
require "opentelemetry-instrumentation-sqlite3"

OpenTelemetry::SDK.configure do |c|
  c.use "OpenTelemetry::Instrumentation::SQLite3"
end
```

### With options

```ruby
OpenTelemetry::SDK.configure do |c|
  c.use "OpenTelemetry::Instrumentation::SQLite3", {
    db_statement: :obfuscate,
    obfuscation_limit: 2000,
    record_exception: true
  }
end
```

All `SQLite3::Database` queries are now traced:

```ruby
db = SQLite3::Database.new("app.sqlite3")
db.execute("SELECT * FROM users WHERE id = ?", [42])
# => Creates a span: name="SELECT app.sqlite3", db.system="sqlite", db.statement="SELECT * FROM users WHERE id = ?"
```

## Configuration

| Option | Default | Values | Description |
|--------|---------|--------|-------------|
| `db_statement` | `:obfuscate` | `:omit`, `:include`, `:obfuscate` | Controls SQL capture in spans |
| `obfuscation_limit` | `2000` | Integer | Max length of obfuscated SQL |
| `record_exception` | `true` | Boolean | Record exceptions on spans |

**`db_statement` modes:**

- `:obfuscate` (default) — captures SQL with literal values replaced by `?`
- `:include` — captures raw SQL including all literal values
- `:omit` — no SQL captured in spans

> **Note:** Avoid `:include` in production if your queries contain sensitive data (passwords, PII, tokens). The default `:obfuscate` mode is recommended.

## Semantic Conventions

Each span includes:

| Attribute | Value | Example |
|-----------|-------|---------|
| `db.system` | `"sqlite"` | `"sqlite"` |
| `db.name` | Database filename (basename) | `"app.sqlite3"` |
| `db.operation` | SQL operation (first keyword) | `"SELECT"` |
| `db.statement` | SQL (per `db_statement` config) | `"SELECT * FROM users WHERE id = ?"` |

SQLite-specific simplifications (compared to PG/Trilogy instrumentations):

- No `net.peer.name` or `net.peer.port` — SQLite is an embedded database
- No `db.user` — SQLite has no authentication
- `db.name` is `nil` for in-memory databases (`:memory:`)

## Instrumented Methods

The following `SQLite3::Database` methods are wrapped with spans:

- `execute`
- `execute2`
- `execute_batch`
- `execute_batch2`
- `query`

## Compatibility

- Ruby >= 3.1
- sqlite3 gem >= 2.0, < 3.0

## License

Apache-2.0. See [LICENSE](LICENSE).
