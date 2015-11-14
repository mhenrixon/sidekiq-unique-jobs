## v4.0.9

- Add command line and console extensions for removal of unique jobs (c292d87)

## v4.0.8

- Use unique arguments for the `WhileExecuting` lock (#127)
- Delicensed code (#132)
- Fix queuing unique jobs (#138)

## v4.0.7

- Use unique arguments for the `WhileExecuting` lock (#127)
- See also https://github.com/mhenrixon/sidekiq-unique-jobs/releases/tag/v4.0.7

## v4.0.6

- Removes enforced uniqueness for all jobs (#127)

## v4.0.5

- Forces look for `Sidekiq::Testing` in Sidekiq without ancestors #129

## v4.0.4

- Fix usage with active job
- Get rid of unneeded configuration options `unique_args_enabled` (just use whatever unique argument that is configured).

## v4.0.3

- Remove `unique_lock` and use `unique: ` to set this like in `unique: :until_timeout`
- Warn when using `unique: true` and suggest to change it to what we need with a fallback.
- Create constants for hash keys to avoid having to fix spelling or for renaming keys only having to be done in one place and avoid having to type .freeze everywhere.
- Move all explicit logic out from the server middle ware and make it just call execute on the instance of the lock class (prepare for allowing custom locking classes to be used).
- Create a new job for scheduling jobs after it started executing but only allow one job to run at the same time.

## v4.0.2

- Fix a problem with an unresolved reference

## v4.0.1

- Get rid of development dependency on active support (causing trouble with jruby)

## v4.0.0

- Improved uniqueness handling (complete refactoring, upgrade with causion)
- 100% breaking changes

## v3.0.15

- Jobs only ever unlock themselves now (see #96 & #94 for info) thanks @pik
- Slight refactoring and internal renaming. Shouldn't affect anyone
- Run locks as an alternative when you only need to prevent the same job running twice but want to be able to schedule it multiple times. See #99 (thanks @pik)
- Fixes #90, #92, #93, #97, #98, #100, #101, #105

## v3.0.14

- Improve uniqueness check performance thanks @mpherham
- Remove locks in sidekiq fake testing mode
- Do not unlock jobs when sidekiq is shutting down

## v3.0.13

- Improved testing capabilities (testing uniqueness should not work better)
- Configurable logging of duplicate payloads
- Now requires `sidekiq_unique_ext` and `sidekiq/api` by default
- Drop support for MRI 1.9 and sidekiq 2

## v3.0.11

- Ensure threadsafety (thanks to adstage-david)

## v3.0.9
- Fixed that all jobs stopped processing

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
