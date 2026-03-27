# Testing Rules

## TDD Workflow

Follow RED -> GREEN -> REFACTOR:

1. **RED**: Write a failing test first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve code while keeping tests green

## Coverage Requirements

- **80% minimum** for all code
- **100% required** for:
  - Lock type implementations
  - Lua scripts
  - Middleware (client and server)
  - Conflict strategies
  - Orphan reapers

## Test Type Preference

| Feature involves | Use |
|-----------------|-----|
| Lock lifecycle | Integration spec with real Redis |
| Lua scripts | Lua-specific spec with Redis |
| Middleware behavior | Integration spec |
| Configuration | Unit spec |
| Conflict strategies | Integration spec |
| Web UI | Feature spec |

## RSpec Conventions

```ruby
# Use let for setup
let(:item) { { "class" => "MyWorker", "args" => [1] } }

# Use subject for the thing being tested
subject { described_class.new(item) }

# Use contexts for scenarios
context "when lock exists" do
  before { acquire_lock }
  it { is_expected.to be_locked }
end

# Use factories/helpers, not fixtures
```

## Redis in Tests

- Use `Sidekiq::Testing.disable!` when testing actual uniqueness
- Clear Redis between tests
- Test with real Redis, not mocks (lock behavior is Redis-dependent)
- Test TTL/expiration behavior explicitly

## Test Checklist

- [ ] Tests written BEFORE implementation
- [ ] All tests pass: `bundle exec rspec`
- [ ] Coverage meets requirements
- [ ] No skipped tests without reason
- [ ] Lock lifecycle fully tested (acquire -> execute -> release)
- [ ] Edge cases covered (expired locks, race conditions, reaper cleanup)
