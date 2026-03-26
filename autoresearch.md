# Autoresearch: Reduce Redis Commands Per Lock Lifecycle

## Configuration
- **Metric**: redis_commands_per_cycle (commands, ↓ minimize)
- **Secondary metrics**: keys_while_locked, ops_per_sec
- **Benchmark**: `bash autoresearch.sh`
- **Files in scope**:
  - `lib/sidekiq_unique_jobs/locksmith.rb`
  - `lib/sidekiq_unique_jobs/key.rb`
  - `lib/sidekiq_unique_jobs/lua/queue.lua`
  - `lib/sidekiq_unique_jobs/lua/lock.lua`
  - `lib/sidekiq_unique_jobs/lua/unlock.lua`
  - `lib/sidekiq_unique_jobs/lua/queue_and_lock.lua`
  - `lib/sidekiq_unique_jobs/lua/shared/_common.lua`
- **Metric extraction**: `METRIC redis_commands_per_cycle=<value>`
- **Started**: 2026-03-13

## Baseline
- **redis_commands_per_cycle**: 34.0
- **Commit**: f67f3464

## Current Best
- **redis_commands_per_cycle**: 8.0 (-76.5% from baseline)
- **until_executed_commands** (single): 8 (was 35)
- **until_expired_commands** (single): 10 (was 37)
- **while_executing_commands** (single): 8 (was 35)
- **keys_while_locked**: 3 (digest, locked hash, digests sorted set)
- **keys_after_unlock**: 0 (was 1)
- **ops_per_sec**: ~2082 until_executed, ~4736 until_expired, ~6328 while_executing
- **Commit**: 3357538e

## Strategy Log

### Run 1: Batch UNLINK queued+primed in lock.lua
- Result: 34.0 → 34.0 (marginal) | kept

### Run 2: Defer LLEN/HLEN in unlock.lua, batch UNLINK
- Result: 34.0 → 29.0 (-14.7%) | kept (BIG WIN)

### Run 3: Defer LLEN/HLEN in queue.lua
- Result: 29.0 → 27.0 (-7.4%) | kept

### Run 4: SET NX in queue.lua
- Result: 27.0 → 26.0 (-3.7%) | kept

### Run 5: Remove redundant locked? pre-check before unlock
- Result: 26.0 → 25.0 (-3.8%) | kept

### Run 6: Remove locked? pre-check in lock! (DEAD END)
- Status: reverted (3 test failures — needed for re-lock semantics)

### Run 7: Skip LREM in unlock.lua when holding lock
- Result: 25.0 → 23.0 (-8%) | kept

### Run 8: Skip LREM in lock.lua for limit=1, just UNLINK
- Result: 23.0 → 21.0 (-8.7%) | kept

### Run 9: Fast-path unlock for single-lock
- Result: 21.0 → 19.0 (-9.5%) | kept (BIG WIN)

### Run 10: Lock.lua UNLINK in duplicate path
- Result: 19.0 → 19.0 (correctness) | kept

### Run 11: Combined queue_and_lock.lua for sync path
- Merged queue+LMOVE+lock into single Lua script
- Result: 19.0 → 13.0 (-31.6%) | kept (BIG WIN)

### Run 12: Skip Ruby-side locked? for sync path
- Result: 13.0 → 13.0 (marginal) | kept

### Run 13: Skip sentinel LPUSH+PEXPIRE for sync-locked single locks
- Pass sync_locked flag through argv, skip when no BLMOVE waiters
- Result: 13.0 → 11.0 (-15.4%) | kept (BIG WIN)

### Run 14: Fast-path unlock for sync single locks, skip HEXISTS
- For sync path, we KNOW job holds lock → skip HEXISTS check
- Result: 11.0 → 10.0 (-9.1%) | kept

### Run 15: HLEN-first check in queue_and_lock.lua for limit=1
- Replace HEXISTS+HLEN with single HLEN (saves 1 cmd on first lock)
- Result: 10.0 → 9.0 (-10%) | kept

### Run 16: Extend sync-locked fast path for until_expired
- until_expired skips HEXISTS+LPUSH+PEXPIRE in sync unlock path
- Result: 9.0 → 9.0 (until_expired: 13→10) | kept

### Run 17: Skip redundant HDEL before UNLINK(locked) for sync single-lock
- For limit=1, UNLINK(locked) deletes entire hash → HDEL is redundant
- Result: 9.0 → 8.0 (-11.1%) | kept

### Run 18: Simplify SET NX to unconditional SET
- Result: 8.0 → 8.0 (code cleanup) | kept

## Dead Ends
1. Removing `locked?` pre-check in `lock!` — needed for re-lock semantics (3 failures)
2. Removing digest string key — middleware and tests require it to exist while locked
3. ~~Merging queue.lua + lock.lua~~ — Done in Run 11 via queue_and_lock.lua

## Key Wins
1. **Combined queue_and_lock.lua** — Merge 3 scripts into 1 atomic operation for sync path. (Saved ~6 commands)
2. **Defer upfront variable computation** — LLEN/HLEN deferred to point of use. (Saved ~5 commands)
3. **Batch UNLINK calls** — Multiple UNLINK consolidated into single calls. (Saved ~3 commands)
4. **Fast-path for limit=1** — Skip unnecessary checks when state is known. (Saved ~4 commands)
5. **Skip sentinel for sync path** — No BLMOVE waiters → skip LPUSH+PEXPIRE. (Saved 2 commands)
6. **Skip HEXISTS/HDEL in sync unlock** — Known lock holder → skip checks. (Saved 2 commands)
7. **HLEN-first check** — Single HLEN replaces HEXISTS+HLEN for limit=1. (Saved 1 command)

## Remaining Command Breakdown (8 per cycle)
### queue_and_lock.lua (5 commands)
1. evalsha — execute Lua script
2. HLEN locked — check if lock is available
3. SET digest job_id — create digest key (required by middleware/UI)
4. ZADD digests score digest — register in sorted set (required by reaper/UI)
5. HSET locked job_id time — acquire the lock

### unlock.lua (3 commands)
1. evalsha — execute Lua script
2. UNLINK digest info locked primed — delete all lock keys
3. ZREM digests digest — remove from sorted set

## Theoretical Minimum Analysis
All 8 remaining commands are structurally necessary:
- 2 evalsha: Lua scripts for atomicity (1 lock + 1 unlock)
- HLEN: prevent exceeding lock limit
- SET: digest key required by middleware ecosystem
- ZADD: sorted set required by reaper/web UI
- HSET: the lock itself
- UNLINK: cleanup 4 keys in 1 command
- ZREM: reverse of ZADD

**The only path to fewer commands would require architectural changes** (e.g., eliminating the digest string key requirement, or using a single data structure instead of hash + sorted set + string).
