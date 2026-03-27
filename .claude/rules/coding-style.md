# Coding Style Rules

## File Organization

**MANY SMALL FILES > FEW LARGE FILES**

- High cohesion, low coupling
- 200-400 lines typical
- 800 lines maximum per file
- Extract complex logic to dedicated classes
- Organize by concern (lock types, strategies, redis wrappers)

## Ruby Style

### Classes & Methods

```ruby
# Good: Small, focused methods
def lock
  validate_lock_config
  acquire_lock
  register_job
end

# Bad: Giant methods doing everything
def process_everything
  # 200 lines of code...
end
```

### Error Handling

```ruby
# Good: Specific error handling
def execute
  lock
  yield
rescue SidekiqUniqueJobs::LockTimeout => e
  reflect(:timeout, item)
  call_strategy(on_conflict)
rescue => e
  reflect(:execution_failed, item)
  raise
ensure
  unlock
end

# Bad: Swallowing errors
def execute
  lock
  yield
rescue StandardError
  nil
end
```

### Lua Scripts

```lua
-- Good: Use shared functions, parameterized keys
local function lock_exists(key)
  return redis.call("EXISTS", key) == 1
end

-- Bad: String concatenation with user input
redis.call("SET", "prefix:" .. user_input, value)
```

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Methods are small (<30 lines ideal, <50 max)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling with reflection
- [ ] All Redis operations are atomic (Lua)
- [ ] Rubocop passes
