## v3.0.8
- Unique extensions for Web GUI by @rickenharp. Uniqueness will now be removed when a job is.

## v3.0.7
- Internal refactoring
- Improved coverage
- Rubocop style validation

## v3.0.5
- Fixed the different test modes (major thanks to @salrepe)

## v3.0.2
- Removed runtime dependency on mock_redis (add `gem 'mock_redis'` to your desired group to use it)

## v2.7.0
- Use mock_redis when testing in fake mode
- Replace minitest with rspec
- Add codeclimate badge
- Update travis with redis-server

## v2.6.5
- via @sax - possibility to set which arguments should be counted as unique - https://github.com/form26/sidekiq_unique_jobs/pull/12
- via @eduardosasso - possibility to set which arguments should be counted as unique - https://github.com/form26/sidekiq_unique_jobs/pull/11
- via @KensoDev - configuration of default expiration - https://github.com/form26/sidekiq_unique_jobs/pull/9

## v2.1.0

Extracted the unique jobs portion from sidekiq main repo since @mperham dropped support for it.
