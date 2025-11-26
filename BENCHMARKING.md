# Performance Benchmarking Guide

This guide explains how to run performance benchmarks for sidekiq-unique-jobs and compare results across branches.

## Available Benchmark Scripts

### 1. `bin/benchmark` - Comprehensive Benchmarks
Full suite of benchmarks testing all aspects of the gem:
- Lock acquisition
- Lock contention
- Digest generation
- Conflict resolution strategies
- Concurrent locking
- Memory usage

**Usage:**
```bash
bin/benchmark
```

### 2. `bin/bench` - Orphan Reaper Benchmarks
Focused benchmarks for the orphan reaper (Ruby vs Lua implementation):

**Usage:**
```bash
bin/bench
```

### 3. `bin/benchmark_improvements` - Improvement-Focused Benchmarks
Targeted benchmarks for specific performance improvements:
- Non-blocking lock acquisition
- Orphan reaper Lua optimization
- Lock TTL calculation
- Scripts class operations
- Thread-safe concurrent operations
- Callback exception handling
- Blocking Redis operations

**Usage:**
```bash
bin/benchmark_improvements
```

**Output:** Displays detailed benchmark results with iterations per second (IPS) for each test.

### 4. `bin/compare_performance` - Branch Comparison Tool
Automated script to compare performance between two git branches:

**Usage:**
```bash
# Compare current branch with main
bin/compare_performance

# Compare specific branches
bin/compare_performance main improved-exception-handling

# Compare with custom base and comparison branches
bin/compare_performance v8.0.11 feature-branch
```

**What it does:**
1. Checks out the base branch (default: `main`)
2. Runs full benchmarks and saves results
3. Checks out the comparison branch (default: current branch)
4. Runs full benchmarks and saves results
5. Returns to your original branch
6. Displays a summary comparison of key metrics

**Output:**
- Summary of key performance improvements
- Full results saved to `tmp/benchmark_results/`
- Suggestions for viewing detailed comparisons

## Prerequisites

The benchmark scripts will automatically install required gems:
- `benchmark-ips` - For measuring iterations per second
- `benchmark-memory` - For measuring memory allocation

## Running Benchmarks

### Quick Start

To verify improvements in the current branch compared to main:

```bash
# Run the comparison tool
bin/compare_performance main improved-exception-handling
```

This will:
- Run benchmarks on both branches
- Display key performance metrics
- Save detailed results for further analysis

### Manual Comparison

If you prefer to run benchmarks manually:

```bash
# Save current branch name
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Benchmark main branch
git checkout main
bin/benchmark_improvements > results_main.txt

# Benchmark your branch
git checkout $CURRENT_BRANCH
bin/benchmark_improvements > results_current.txt

# Compare results
diff -y results_main.txt results_current.txt | less
```

## Understanding Results

### Iterations Per Second (IPS)

Higher is better. This measures how many times the operation can be performed per second.

Example output:
```
lock with failure simulation    1.234k i/s
lock and unlock - normal flow   5.678k i/s
```

The "normal flow" is ~4.6x faster than "failure simulation" in this example.

### Comparison Output

The comparison tool shows relative performance:
```
lock with failure simulation:
   main:                        1.234k i/s
   improved-exception-handling: 2.345k i/s  <- ~90% improvement!
```

### Memory Usage

Lower is better. Shows memory allocated during operations.

Example:
```
100 lock/unlock cycles
  allocated:    45.2 MB
  retained:     123 KB
```

## Performance Improvements Tracked

The `bin/benchmark_improvements` script specifically tracks these improvements:

1. **Non-Blocking Lock Acquisition**
   - Changed `wait: 1` to `wait: 0` in exception handling
   - Reduces worker blocking time by 1 second per failure

2. **Orphan Reaper Optimization**
   - Cached digest transformations in Lua
   - Added short-circuit breaks in loops
   - Increased ZSCAN count for better throughput

3. **Lock TTL Calculation**
   - Fixed negative TTL for overdue scheduled jobs
   - Clamps minimum value to 0

4. **Scripts Class Simplification**
   - Used `Concurrent::Map#fetch_or_store` for cleaner code
   - Improved thread-safe lazy loading

5. **Thread-Safe Config Access**
   - Added mutex with double-check locking
   - Prevents race conditions in Redis version fetching

6. **Callback Exception Handling**
   - Don't re-raise callback exceptions after unlock
   - Prevents double job execution

7. **Blocking Redis Operations**
   - Cap blocking wait at 5 seconds (MAX_BLOCKING_WAIT)
   - Prevents indefinite blocking in client middleware

## Interpreting Performance Changes

### Significant Improvements
- **> 20% improvement**: Excellent! Worth highlighting
- **10-20% improvement**: Good improvement
- **5-10% improvement**: Measurable improvement
- **< 5% improvement**: Marginal (could be noise)

### Expected Improvements from Recent Optimizations

Based on our changes, expect to see:

1. **Orphan Reaper**: 20-40% improvement (cached transformations, short-circuits)
2. **Lock with Failure**: 50-100% improvement (non-blocking wait)
3. **Concurrent Operations**: 10-20% improvement (thread-safe config)
4. **TTL Calculations**: 5-10% improvement (edge case handling)

## Continuous Performance Monitoring

### Best Practices

1. **Run on a quiet machine**: Close other applications to reduce noise
2. **Run multiple times**: Results can vary, run 3-5 times and average
3. **Use consistent Redis**: Same Redis version and configuration
4. **Warm up**: The first run may be slower (JIT compilation, etc.)

### Adding New Benchmarks

To add a new benchmark to `bin/benchmark_improvements`:

```ruby
puts "\n" + "=" * 80
puts "BENCHMARK N: Your Benchmark Name"
puts "Improvement: Description of what was improved"
puts "=" * 80

Benchmark.ips do |x|
  x.config(time: 5, warmup: 2)

  x.report("test case 1") do
    # Your benchmark code here
  end

  x.report("test case 2") do
    # Another test case
  end

  x.compare! # Optional: shows relative performance
end
```

## Troubleshooting

### Redis Connection Issues

If you see Redis connection errors:
```bash
# Check Redis is running
redis-cli ping

# Use custom Redis URL
REDIS_URL=redis://localhost:6379/1 bin/benchmark_improvements
```

### Out of Memory

If benchmarks crash with OOM:
- Reduce COUNT in concurrent benchmarks
- Flush Redis between benchmarks
- Check for memory leaks in new code

### Slow Benchmarks

If benchmarks take too long:
- Reduce `time` parameter (default: 5 seconds)
- Reduce iteration counts
- Skip memory benchmarks

## Results Archive

Benchmark results are saved to `tmp/benchmark_results/`:
```
tmp/benchmark_results/
├── results_main.txt
├── results_improved-exception-handling.txt
└── ...
```

These files are gitignored but useful for historical comparison.

## CI/CD Integration

To run benchmarks in CI:

```yaml
# .github/workflows/benchmark.yml
name: Performance Benchmarks

on:
  pull_request:
    branches: [main]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    services:
      redis:
        image: redis:7
        ports:
          - 6379:6379
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      - name: Run benchmarks
        run: bin/benchmark_improvements
      - name: Compare with main
        run: |
          git fetch origin main
          bin/compare_performance origin/main HEAD
```

## Further Reading

- [benchmark-ips documentation](https://github.com/evanphx/benchmark-ips)
- [benchmark-memory documentation](https://github.com/michaelherold/benchmark-memory)
- [Ruby Performance Optimization](https://pragprog.com/titles/adrpo/ruby-performance-optimization/)
