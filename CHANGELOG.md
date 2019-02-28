# Change Log

## [v6.0.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.12) (2019-02-28)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.11...v6.0.12)

**Fixed bugs:**

- we are receiving SidekiqUniqueJobs::ScriptError "Problem compiling convert\_legacy\_lock" after upgrading from 5.0.10 -\> 6.0.11 [\#377](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/377)
- Fix converting legacy locks [\#378](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/378) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.11) (2019-02-24)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.10...v6.0.11)

**Implemented enhancements:**

- Reduce leftover keys [\#374](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/374) ([mhenrixon](https://github.com/mhenrixon))
- Prepare for sidekiq 6 [\#373](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/373) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Prevent memory leaks \(many locks stay in memory\) [\#368](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/368)
- :until\_and\_while\_executing not processing queued jobs after executing [\#355](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/355)
- Version 6: lets you schedule job with missing arguments [\#351](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/351)
- Version 6 Ignores Jobs Enqueued in Version 5 [\#345](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/345)
- Job will not enqueue even with no existing match [\#342](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/342)
- Convert v5 locks when needed [\#375](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/375) ([mhenrixon](https://github.com/mhenrixon))
- Reduce leftover keys [\#374](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/374) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Infinite lock using until\_and\_while\_executing after sidekiq restart [\#361](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/361)
- getting a crash using lock\_expiration on v6.0.6 [\#350](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/350)
- Problem when job failed and is retrying [\#332](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/332)

**Merged pull requests:**

- Clarify lock expiration in readme [\#376](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/376) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.10) (2019-02-23)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.9...v6.0.10)

**Implemented enhancements:**

- Log job silently complete [\#371](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/371) ([tadejm](https://github.com/tadejm))

**Closed issues:**

- Unsure of sane defaults [\#372](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/372)

## [v6.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.9) (2019-02-11)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.8...v6.0.9)

**Implemented enhancements:**

- Delete all locks button [\#357](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/357)
- John denisov add delete all button to web [\#370](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/370) ([mhenrixon](https://github.com/mhenrixon))
- Various upgrades [\#366](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/366) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.8) (2019-01-10)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.7...v6.0.8)

**Fixed bugs:**

- Close \#359 [\#364](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/364) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Automatic unlock of jobs [\#362](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/362)
- \(6.0.7\) `uniquejobs:{digest}:AVAILABLE` keys never expire [\#359](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/359)
- Strange behavior using strategy "reject" with "until\_executed" [\#358](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/358)
- Pinpointing issues with unique digests not being removed [\#353](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/353)

**Merged pull requests:**

- update changelog [\#356](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/356) ([camallen](https://github.com/camallen))

## [v6.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.7) (2018-11-29)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.11...v6.0.7)

**Fixed bugs:**

- Version 5: Job ID Hash Entries Not Removed if Unique Key Expires [\#346](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/346)
- Move the lpush last [\#354](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/354) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- First job never unlocks the lock / Endless waiting [\#352](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/352)
- Version 5&6: uniqueness not respected for Job without params [\#349](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/349)

## [v5.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.11) (2018-11-19)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.6...v5.0.11)

**Implemented enhancements:**

- More integration tests [\#329](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/329) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Always Remove Job ID from uniquejobs Hash [\#347](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/347) ([chadrschroeder](https://github.com/chadrschroeder))
- Convert expiration time to integer [\#330](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/330) ([dareddov](https://github.com/dareddov))

**Closed issues:**

- concurrent-ruby 1.1.1 is causing this gem to break [\#340](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/340)
- lock remains after job not properly finish [\#339](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/339)
- Using a different Redis instance [\#337](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/337)
- Using :until\_and\_while\_executing not yielding expected results [\#336](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/336)
- "payload is not unique", but cannot find digest or scheduled job [\#335](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/335)
- Confused with UntilExecuted documenation [\#326](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/326)
- Job never requeued after raising unhandled error with until\_and\_while\_executing? [\#322](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/322)

**Merged pull requests:**

- Do not build keys on lua scripts [\#348](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/348) ([pacoguzman](https://github.com/pacoguzman))
- fix CHANGELOG syntax [\#344](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/344) ([timoschilling](https://github.com/timoschilling))
- Define Config class inside SidekiqUniqueJobs module [\#343](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/343) ([Slike9](https://github.com/Slike9))
- fix readme testing section [\#333](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/333) ([edmartins](https://github.com/edmartins))
- Fix typo in documentation \[ci-skip\] [\#327](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/327) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.6) (2018-08-09)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.5...v6.0.6)

**Implemented enhancements:**

- Adds coverage for job retries [\#321](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/321) ([mhenrixon](https://github.com/mhenrixon))
- Internal refactoring [\#318](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/318) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Unique UntilExecuted not working while the job is executing? [\#319](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/319)

## [v6.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.5) (2018-08-07)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.4...v6.0.5)

**Fixed bugs:**

- Unlock instead of signal [\#317](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/317) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Why is lock\_timeout: nil VERY DANGEROUS? [\#313](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/313)

## [v6.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.4) (2018-08-02)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.3...v6.0.4)

**Fixed bugs:**

- Fix the broken expiration [\#316](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/316) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Question about until\_timeout with 6.0.0 [\#303](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/303)

## [v6.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.3) (2018-08-02)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.2...v6.0.3)

**Fixed bugs:**

- Enable replace strategy [\#315](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/315) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Sidekiq Web Pagination Broken [\#309](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/309)

**Merged pull requests:**

- Correct documentation typo \[ci skip\] [\#312](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/312) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.2) (2018-08-01)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.1...v6.0.2)

**Fixed bugs:**

- Not unlocking automatically \(version 6.0.0rc5\) [\#293](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/293)
- Bug fixes [\#310](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/310) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.1) (2018-07-31)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0...v6.0.1)

**Fixed bugs:**

- :until\_executed is throwing errors and not requeuing the job. [\#256](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/256)
- Remove unused method [\#307](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/307) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- ArgumentError: sidekiq\_unique\_jobs/web breaks sidekiq Retries page [\#306](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/306)
- If the job dies, it doesn't remove the lock [\#304](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/304)

**Merged pull requests:**

- Dead jobs [\#308](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/308) ([mhenrixon](https://github.com/mhenrixon))
- Fix require path for sidekiq\_unique\_jobs/web [\#305](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/305) ([soundasleep](https://github.com/soundasleep))

## [v6.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0) (2018-07-27)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc8...v6.0.0)

## [v6.0.0.rc8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc8) (2018-07-24)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc7...v6.0.0.rc8)

**Implemented enhancements:**

- Add RequeueWhileExecuting strategy [\#223](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/223)
- New feature: Replace original job if duplicate is added [\#177](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/177)
- Add a replace strategy for client locks [\#302](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/302) ([mhenrixon](https://github.com/mhenrixon))

**Merged pull requests:**

- Add more details about testing uniqueness [\#301](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/301) ([mhenrixon](https://github.com/mhenrixon))
- Update README.md [\#300](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/300) ([pirj](https://github.com/pirj))

## [v6.0.0.rc7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc7) (2018-07-23)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc6...v6.0.0.rc7)

**Implemented enhancements:**

- Sidekiq web [\#297](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/297) ([mhenrixon](https://github.com/mhenrixon))
- Document code [\#296](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/296) ([mhenrixon](https://github.com/mhenrixon))
- Rename to `unique:` to `lock:` [\#295](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/295) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Unique Job not work while play with crontab [\#294](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/294)
- Making the GEM compatible with Ruby \< 2.3 [\#291](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/291)

**Merged pull requests:**

- Adds changelog entry [\#299](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/299) ([mhenrixon](https://github.com/mhenrixon))
- Fix README [\#298](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/298) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc6) (2018-07-15)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc5...v6.0.0.rc6)

**Fixed bugs:**

- Don't unlock when worker raises an error [\#290](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/290) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Locking with retries [\#289](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/289)

**Merged pull requests:**

- Readme [\#288](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/288) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc5) (2018-06-30)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc4...v6.0.0.rc5)

**Fixed bugs:**

- bundle exec jobs console does not work [\#253](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/253)
- Rename command line binary [\#287](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/287) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc4) (2018-06-30)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc3...v6.0.0.rc4)

**Implemented enhancements:**

- Prepare for v6 [\#286](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/286) ([mhenrixon](https://github.com/mhenrixon))
- Only unlock not delete [\#285](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/285) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc3) (2018-06-29)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc2...v6.0.0.rc3)

**Fixed bugs:**

- Fix waiting for locks [\#284](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/284) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc2) (2018-06-26)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.rc1...v6.0.0.rc2)

**Implemented enhancements:**

- Within tests: workers enqueued in the future don't clear their unique locks after being drained/executed [\#254](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/254)
- Unexpected behavior with until\_executed [\#250](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/250)

**Fixed bugs:**

- Unique job needs to be unlocked manually? [\#261](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/261)
- Duplicate jobs getting created [\#257](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/257)
- Multiple non-unique jobs with until\_executed? [\#255](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/255)
- :until\_executing not unlocking when starting to run [\#245](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/245)
- Drop jobs hash [\#282](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/282) ([mhenrixon](https://github.com/mhenrixon))

**Closed issues:**

- Difference between :until\_and\_while\_executing vs :until\_executed is not clear [\#249](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/249)
- Deprecated Documentation [\#246](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/246)
- Are we meant to manually expire the unique jobs hash? [\#234](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/234)
- How :until\_executing works ? Run job only once and discard new jobs while another job is executing [\#226](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/226)

**Merged pull requests:**

- Remove some misleading information [\#283](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/283) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.rc1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.rc1) (2018-06-26)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.beta2...v6.0.0.rc1)

**Implemented enhancements:**

- Legacy support [\#280](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/280)
- Adds legacy support [\#281](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/281) ([mhenrixon](https://github.com/mhenrixon))
- Adds guard-reek [\#279](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/279) ([mhenrixon](https://github.com/mhenrixon))
- Fix UntilExpired [\#278](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/278) ([mhenrixon](https://github.com/mhenrixon))

**Fixed bugs:**

- Fix UntilExpired [\#278](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/278) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.beta2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.beta2) (2018-06-25)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.beta1...v6.0.0.beta2)

**Implemented enhancements:**

- Make locks more robust [\#277](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/277) ([mhenrixon](https://github.com/mhenrixon))
- Rename UntilTimeout -\> UntilExpired [\#276](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/276) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.beta1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.beta1) (2018-06-22)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v6.0.0.beta...v6.0.0.beta1)

**Implemented enhancements:**

- Code smells [\#275](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/275) ([mhenrixon](https://github.com/mhenrixon))
- Reject while scheduling [\#273](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/273) ([mhenrixon](https://github.com/mhenrixon))
- Improve testing [\#272](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/272) ([mhenrixon](https://github.com/mhenrixon))

## [v6.0.0.beta](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v6.0.0.beta) (2018-06-17)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.10...v6.0.0.beta)

**Implemented enhancements:**

- Until and while executing [\#271](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/271) ([mhenrixon](https://github.com/mhenrixon))
- Solidify master [\#270](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/270) ([mhenrixon](https://github.com/mhenrixon))
- Minor adjustments [\#268](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/268) ([mhenrixon](https://github.com/mhenrixon))
- Use ruby 2.5.1 [\#267](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/267) ([mhenrixon](https://github.com/mhenrixon))
- Add explicit concurrent-ruby dependency. [\#265](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/265) ([brettburley](https://github.com/brettburley))

**Fixed bugs:**

- Allow `jobs keys` to default to listing all keys [\#252](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/252) ([soundasleep](https://github.com/soundasleep))

**Closed issues:**

- Incomplete sentence in README [\#264](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/264)
- ActiveJob and Sidekiq::Worker [\#259](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/259)
- ActiveJob and Sidekiq::Worker [\#258](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/258)
- Non-unique jobs can be added even when `sidekiq\_options unique: :until\_executed` [\#251](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/251)
- Trouble with "inline" mode [\#243](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/243)
- Sidekiq::Worker.set not working with sidekiq-unique-jobs [\#242](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/242)
- sidekiq-unique-job with ActiveJob [\#238](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/238)
- Deadlock using :while\_executing? [\#233](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/233)

**Merged pull requests:**

- Improve documentation [\#269](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/269) ([mhenrixon](https://github.com/mhenrixon))
- Remove unnecessary monkey patches for String [\#262](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/262) ([zormandi](https://github.com/zormandi))
- README \> While Executing: remove unnecessary word [\#260](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/260) ([TimCannady](https://github.com/TimCannady))
- Don't skip monkeypatches if ActiveSupport present [\#248](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/248) ([dleavitt](https://github.com/dleavitt))
- Better runtime locks [\#241](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/241) ([mhenrixon](https://github.com/mhenrixon))

## [v5.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.10) (2017-08-19)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.9...v5.0.10)

**Closed issues:**

- Version v5.0.5 might have introduced a breaking change in while\_executing and was not documented [\#230](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/230)
- String arguments not seen as unique  [\#222](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/222)
- unique\_args method suppresses all `NameError` exceptions [\#219](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/219)

**Merged pull requests:**

- Various improvements [\#240](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/240) ([mhenrixon](https://github.com/mhenrixon))
- Fix: uninitialized constant CustomQueueJob on rspec [\#239](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/239) ([dalpo](https://github.com/dalpo))

## [v5.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.9) (2017-07-06)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.8...v5.0.9)

**Closed issues:**

- The work of several unique sidekiq tasks within one queue [\#225](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/225)
- Missing documentation on activejob usage [\#221](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/221)

**Merged pull requests:**

- Your testing lib is broken and don't permit to test uniqueness of jobs [\#232](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/232) ([keysen](https://github.com/keysen))
- Use hscan for Util\#expire [\#229](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/229) ([dmkc](https://github.com/dmkc))
- Fixed documentation example about unique\_args [\#228](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/228) ([andresakata](https://github.com/andresakata))
- Fix filename [\#224](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/224) ([ikataitsev](https://github.com/ikataitsev))

## [v5.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.8) (2017-05-03)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.7...v5.0.8)

**Closed issues:**

- Using JSON.parse in delete\_by\_value\_ext break compatiblity with other Sidekiq extensions [\#220](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/220)
- Is it possible to get the Job ID of original job? [\#217](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/217)

## [v5.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.7) (2017-04-26)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.6...v5.0.7)

**Closed issues:**

- Can't delete Sidekiq::Job after 5.0.1 [\#218](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/218)
- Uniqueness across workers [\#210](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/210)

## [v5.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.6) (2017-04-23)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.5...v5.0.6)

**Closed issues:**

- Different unique arguments depending on lock type [\#203](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/203)
- Strategy until\_and\_while\_executing not working properly [\#199](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/199)
- while\_executing working wrong [\#193](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/193)

## [v5.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.5) (2017-04-23)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.4...v5.0.5)

**Merged pull requests:**

- Fixed typo on README.md [\#216](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/216) ([jsantos](https://github.com/jsantos))

## [v5.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.4) (2017-04-18)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.3...v5.0.4)

## [v5.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.3) (2017-04-18)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.2...v5.0.3)

## [v5.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.2) (2017-04-17)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.1...v5.0.2)

**Closed issues:**

- Uniqueness should not survive Class.jobs.clear [\#214](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/214)
- when arguments are empty then unique\_args proc/method is not executed [\#201](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/201)

## [v5.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.1) (2017-04-16)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v5.0.0...v5.0.1)

**Closed issues:**

- Removing "uniquejobs" hash? [\#213](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/213)
- deprecation warnings with redis-namespace 2.0 [\#212](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/212)
- Unclear docs / examples for unique\_args [\#211](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/211)
- Jobs Console fails to launch [\#208](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/208)
- Util.del Redis::CommandError: ERR syntax error [\#207](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/207)
- version 4.0.19 [\#206](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/206)
- Job.delete does not remove lock in all circumstances [\#205](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/205)
- disappearing jobs - known issue in conjunction with other extensions? [\#202](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/202)
- Broken pipe @ io\_write - \<STDERR\> on sidekiq unique jobs [\#198](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/198)
- Doesn't play well with redis-namespace [\#196](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/196)
- SidekiqUniqueJobs::ScriptError [\#192](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/192)

**Merged pull requests:**

- Add the possibility to clear the hash [\#215](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/215) ([mhenrixon](https://github.com/mhenrixon))

## [v5.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v5.0.0) (2017-04-08)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.18...v5.0.0)

**Fixed bugs:**

- Can't enable testing with newer versions of sidekiq [\#175](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/175)
- strange behaviour [\#172](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/172)

**Closed issues:**

- Could not find a valid gem 'sidekiq-unique-jobs' \(= 3.0.15\) in any repository [\#197](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/197)
- `uniquejobs` hash doesn't get cleaned up [\#195](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/195)
- Code block under "Finer Control over Uniqueness" in your documentation might have the wrong option specified [\#191](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/191)
- not able to run test without live Redis [\#186](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/186)
- unique while not sucessfully completed? [\#185](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/185)
- Duplicate jobs when using :until\_and\_while\_executing [\#181](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/181)
- unique: :while\_executing doesn't remove lock when the Sidekiq node running the job shuts down and terminates the job prematurely [\#170](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/170)
- :while\_executing appears to be broken [\#159](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/159)
- Using ":until\_executing, :until\_executed, :until\_timeout, :until\_and\_while\_executing" all break Sidekiq::Testing [\#157](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/157)
- Way to remove lock in application code [\#147](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/147)

**Merged pull requests:**

- Increase sleep delay in WhileExecuting\#synchronize [\#204](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/204) ([dsander](https://github.com/dsander))
- Ensure job ID removed from uniquejobs hash [\#200](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/200) ([carlosmartinez](https://github.com/carlosmartinez))
- unique args need to be an array [\#194](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/194) ([pboling](https://github.com/pboling))

## [v4.0.18](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.18) (2016-07-24)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.17...v4.0.18)

**Closed issues:**

- ArgumentError: wrong number of arguments \(given 1, expected 2\) [\#190](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/190)
- Should be note on document only works on production mode [\#189](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/189)
- SidekiqUniqueJobs::ScriptError: release\_lock.lua NOSCRIPT No matching script. [\#187](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/187)
- sidekiq-unique-jobs kills sidekiq in production [\#183](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/183)
- Parameters turn into String [\#182](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/182)
- You really helped me today [\#180](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/180)
- 4.0.17 config  [\#171](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/171)
- Problem with releasing uniquejobs locks after timeout expires [\#169](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/169)
- NOSCRIPT No matching script. Please use EVAL. [\#168](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/168)
- Broken compatibility with Sidekiq 3.4 [\#140](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/140)

**Merged pull requests:**

- missed space [\#188](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/188) ([TheBigSadowski](https://github.com/TheBigSadowski))
- Convert unless if to just 1 if [\#179](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/179) ([otzy007](https://github.com/otzy007))
- fix for \#168. Handle the NOSCRIPT by sending the script again [\#178](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/178) ([otzy007](https://github.com/otzy007))
- Fixed gitter badge link [\#176](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/176) ([andrew](https://github.com/andrew))

## [v4.0.17](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.17) (2016-03-02)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.16...v4.0.17)

**Closed issues:**

- No place where I can say "Thank you" for all contributors [\#165](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/165)

## [v4.0.16](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.16) (2016-02-17)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.15...v4.0.16)

**Merged pull requests:**

- Fix for sidekiq delete failing for version 3.4.x  [\#167](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/167) ([theprogrammerin](https://github.com/theprogrammerin))
- Run lock timeout configurable [\#164](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/164) ([Slania](https://github.com/Slania))

## [v4.0.15](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.15) (2016-02-16)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.13...v4.0.15)

**Closed issues:**

- Until timeout question [\#163](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/163)
- Error when run rspec [\#162](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/162)
- Unique job keys never dissapear [\#161](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/161)
- Uniqueness breaks jobs [\#160](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/160)
- Too many open files [\#155](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/155)

**Merged pull requests:**

- Add a Gitter chat badge to README.md [\#166](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/166) ([gitter-badger](https://github.com/gitter-badger))
- Fix test overrides. [\#158](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/158) ([benseligman](https://github.com/benseligman))
- Remove wrong Server::Middleware\#worker\_class override [\#156](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/156) ([vkuznetsov](https://github.com/vkuznetsov))

## [v4.0.13](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.13) (2015-12-16)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.12...v4.0.13)

**Closed issues:**

- Seeing this error with latest version 4.0.12 [\#154](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/154)
- Unique job showing weird behavior [\#153](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/153)

## [v4.0.12](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.12) (2015-12-15)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.11...v4.0.12)

**Closed issues:**

- Can't schedule a job from another job [\#151](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/151)
- perform\_in not working in version 4.0.9 [\#150](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/150)
- `unique: until\_and\_while\_executing` not working as expected [\#146](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/146)
- while\_executing still runs duplicate tasks [\#136](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/136)
- Version 4 Upgrade [\#133](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/133)

## [v4.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.11) (2015-12-12)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.10...v4.0.11)

**Closed issues:**

- Release a new version for Ruby \< 2.1 compatability [\#152](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/152)

## [v4.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.10) (2015-12-12)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.9...v4.0.10)

**Closed issues:**

- Until Executed is taking waiting for unique\_expiration [\#149](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/149)
- Until Executed vs Unique Until And While Executing is confusing in README [\#148](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/148)
- sidekiq-unique-jobs not enabled from sidekiq workers [\#131](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/131)

## [v4.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.9) (2015-11-14)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.8...v4.0.9)

**Closed issues:**

- Error when using unique\_args in 4.0.8 [\#145](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/145)
- Ignore lock when jobs spawned from another sidekiq worker [\#142](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/142)
- Two Rails apps on the same server, but only one Sidekiq instances is working correctly [\#141](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/141)
- ActiveRecord::RecordNotDestroyed: Failed to destroy the record [\#139](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/139)

## [v4.0.8](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.8) (2015-10-31)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.7...v4.0.8)

**Closed issues:**

- Jobs not getting queued in v4 [\#138](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/138)
- Unique args being considered? [\#137](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/137)
- No mention how to test in README [\#135](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/135)
- License Difference [\#132](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/132)

**Merged pull requests:**

- Calculate worker's unique args when a proc or a symbol is specified [\#143](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/143) ([zeqfreed](https://github.com/zeqfreed))
- Fix markdown link formatting [\#134](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/134) ([thbar](https://github.com/thbar))

## [v4.0.7](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.7) (2015-10-14)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.6...v4.0.7)

**Closed issues:**

- docs clarification [\#130](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/130)
- 4.\* is hurting background job workers performance [\#127](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/127)

## [v4.0.6](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.6) (2015-10-14)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.5...v4.0.6)

**Closed issues:**

- NameError: uninitialized constant SidekiqUniqueJobs::RunLockFailed [\#126](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/126)

## [v4.0.5](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.5) (2015-10-13)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.4...v4.0.5)

**Closed issues:**

-  Rails + Sidekiq will go bezerk after sidekiq-unique-jobs testing check. [\#128](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/128)
-  NoMethodError: undefined method `to\_sym' for true:TrueClass [\#125](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/125)
- Redis::CommandError: ERR unknown command 'eval' [\#124](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/124)

**Merged pull requests:**

- Forces to look for testing namespace in Sidekiq and not his ancestors [\#129](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/129) ([antek-drzewiecki](https://github.com/antek-drzewiecki))
- Fix outdated phrasing and add test coverage to readme [\#123](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/123) ([albertyw](https://github.com/albertyw))

## [v4.0.4](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.4) (2015-10-09)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.3...v4.0.4)

**Closed issues:**

- Active job with unique args doesn't work [\#120](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/120)
- 4.0.1 =\> job no longer unique [\#117](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/117)
- Update Changelog and Tags [\#115](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/115)

## [v4.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.3) (2015-10-08)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.2...v4.0.3)

**Closed issues:**

- unique\_unlock\_order - never option [\#122](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/122)
- Run 1 job and queue 1 [\#121](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/121)
- unique\_lock vs unique\_locks typo [\#119](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/119)
- 4.0.2 commited but not released to rubygems? [\#118](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/118)

## [v4.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.2) (2015-10-06)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/4.0.1...v4.0.2)

## [4.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/4.0.1) (2015-10-06)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v4.0.0...4.0.1)

**Closed issues:**

- Don't work with perform\_in [\#114](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/114)
- 3.0.15 apparently breaks inline testing [\#113](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/113)
- sidekiq\_unique record in Redis is not cleaned when foreman process is killed [\#112](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/112)
- Can't ensure unique job simultaneously. [\#111](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/111)
- Job considered as duplicate after completion only in production [\#110](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/110)
- Gem requires Redis 2.6+? [\#109](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/109)
- unable to re-schedule job at specific time [\#108](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/108)
- Documentation Not Clear [\#78](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/78)
- Runtime uniqueness when using :before\_yield as unlock order [\#72](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/72)
- Using with sidekiq delayed extensions [\#45](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/45)

**Merged pull requests:**

- Clean up version 4 upgrade instructions [\#116](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/116) ([albertyw](https://github.com/albertyw))

## [v4.0.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v4.0.0) (2015-10-05)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.11...v4.0.0)

**Implemented enhancements:**

- Duplicated Jobs With Nested Sidekiq Workers [\#10](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/10)

**Closed issues:**

- 3.0.14 Error: ERR wrong number of arguments for 'set' command \(Redis::CommandError\) [\#104](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/104)
- Testing [\#103](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/103)
- Active Job [\#102](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/102)
- Why is SidekiqUnique behaviour applied to regular Workers?  [\#100](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/100)
- Confusing behavior when trying to `\[1,2,3\].each { |n| SomeJob.perform\_in\(n.seconds.from\_now, n\) }` never running, logging as duplicate value [\#98](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/98)
- Scheduled jobs are not unlocked when deleted [\#97](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/97)
- Testing functions should be moved out of production code  [\#95](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/95)
- Jobs can unlock mutexes they don't own  [\#94](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/94)
- Jobs scheduled in the future are never run [\#93](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/93)
- perform\_at and perform\_async do not unique if perform\_at is in the future. [\#91](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/91)
- Latest release is breaking [\#90](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/90)
- Optimize Redis usage [\#89](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/89)
- Unique jobs sets Sidekiq testing to inline! mode [\#88](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/88)
- Test suite unclear on what happens when duplicate job is attempted [\#84](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/84)
- Change log level to info rather than warn [\#80](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/80)
- Jobs are unlocked if they fail and are retried [\#77](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/77)
- Usage of sidekiq-unique-jobs with activejob [\#76](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/76)
- If a job is deleted from the enqueued list, it's still unique and new jobs can't be added. [\#74](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/74)
- Incorrect README re: uniqueness time? [\#73](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/73)
- Sidekiq::Testing inline detection assumes you're always using inline testing [\#71](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/71)
- unique\_args\_enabled has been deprecated, nothing in readme [\#70](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/70)
-  The second job does not run, even if it has different arguments [\#69](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/69)
- Jobs not being executed anymore?? [\#65](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/65)
- mock\_redis and the mess [\#62](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/62)
- What is the exact behavior? [\#47](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/47)
- Throttling jobs [\#39](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/39)
- undefined method `get\_sidekiq\_options' for "MyScheduledWorker":String  [\#27](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/27)
- Crash handling [\#14](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/14)
- Missing info from README [\#6](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/6)

**Merged pull requests:**

- Allow job with jid matching unique lock to pass unique check [\#105](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/105) ([deltaroe](https://github.com/deltaroe))
- Prevent Jobs from deleting mutexes they don't own [\#96](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/96) ([pik](https://github.com/pik))
- Add after unlock hook [\#92](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/92) ([HParker](https://github.com/HParker))
- Do not unlock on sidekiq shutdown [\#87](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/87) ([deltaroe](https://github.com/deltaroe))
- Remove no-op code, protect global space from test code [\#86](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/86) ([stevenjonescgm](https://github.com/stevenjonescgm))
- Remove unique lock when executing and clearing jobs in sidekiq fake mode [\#83](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/83) ([crberube](https://github.com/crberube))
- Fix tests. Tests with latest sidekiq versions and ruby versions [\#82](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/82) ([simonoff](https://github.com/simonoff))
- Duplicate Payload logging configuration [\#81](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/81) ([jprincipe](https://github.com/jprincipe))
- output log if not unique [\#79](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/79) ([sonots](https://github.com/sonots))
- Checking Sidekiq::Testing.inline? on testing strategy and connector [\#75](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/75) ([Draiken](https://github.com/Draiken))

## [v3.0.11](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.11) (2014-12-15)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.10...v3.0.11)

**Closed issues:**

- ConnectionPool used incorrectly - causes deadlocks [\#66](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/66)
- undefined `configuration` when using .configure [\#64](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/64)

**Merged pull requests:**

- Use ConnectionPool blocks to ensure exclusive connection. Closes \#66. [\#67](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/67) ([adstage-david](https://github.com/adstage-david))

## [v3.0.10](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.10) (2014-11-19)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.9...v3.0.10)

**Closed issues:**

- LoadError: cannot load such file -- mock\_redis [\#60](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/60)
- The deprecation message is unclear and unnecessary [\#59](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/59)

**Merged pull requests:**

- Added method name to depreciation warning message [\#61](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/61) ([jamesbowles](https://github.com/jamesbowles))

## [v3.0.9](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.9) (2014-11-05)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.3...v3.0.9)

**Closed issues:**

- sidekiq-unique-jobs prevents not unique jobs creation event with sidekiq inline test mode [\#58](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/58)
- mock redis dependency [\#55](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/55)
- Unique key inconsistency between server and client [\#48](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/48)
- Example Test using Sidekiq::Testing.inline [\#44](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/44)
- Will a second job lose if the job is already queued, or is already scheduled? [\#43](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/43)
- Can you update the change log? [\#42](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/42)

**Merged pull requests:**

- Refactoring connectors to use them in client and server [\#56](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/56) ([salrepe](https://github.com/salrepe))
- Fix dependency error in inline testing connector [\#54](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/54) ([salrepe](https://github.com/salrepe))
- Add extension to Sidekiq API that is uniqueness-aware [\#52](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/52) ([rickenharp](https://github.com/rickenharp))

## [v3.0.3](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.3) (2014-11-03)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.2...v3.0.3)

**Closed issues:**

- is mock\_redis really a runtime dependency? [\#46](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/46)

**Merged pull requests:**

- Unlock testing inline jobs like normal ones [\#53](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/53) ([salrepe](https://github.com/salrepe))
- Declare mock\_redis as development dependency instead of runtime one [\#51](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/51) ([phuongnd08](https://github.com/phuongnd08))

## [v3.0.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.2) (2014-06-08)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v3.0.1...v3.0.2)

**Closed issues:**

- Add unique job key to the message json [\#40](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/40)

**Merged pull requests:**

- Add the unique hash to the message for use by the workers. [\#41](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/41) ([sullimander](https://github.com/sullimander))

## [v3.0.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v3.0.1) (2014-06-08)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.7.0...v3.0.1)

**Closed issues:**

- Support for sidekiq 3? [\#34](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/34)
- Short jobs are not unique for the given time window [\#33](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/33)
- Not all sidekiq:sidekiq\_unique keys are removed from Redis [\#31](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/31)
- What does uniqueness mean in case of this gem? [\#30](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/30)
- Server middleware removes payload hash key before expiration [\#26](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/26)
- Lock remains when running with Sidekiq::Testing.inline! [\#23](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/23)
- What is the use case for the uniqueness window? [\#22](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/22)
- clarification on unique\_args [\#20](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/20)
- payload\_hash staying around [\#13](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/13)

**Merged pull requests:**

- Fix repo URLs for badges [\#38](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/38) ([felixbuenemann](https://github.com/felixbuenemann))
- Clarify README about unique expiration [\#36](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/36) ([spacemunkay](https://github.com/spacemunkay))
- Add option to make jobs unique on all queues [\#32](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/32) ([robinmessage](https://github.com/robinmessage))
- Fix homepage in gemspec [\#29](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/29) ([tmaier](https://github.com/tmaier))

## [v2.7.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.7.0) (2013-11-24)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.3.2...v2.7.0)

**Closed issues:**

- Sidekiq tests failed when sidekiq-unique-jobs is used [\#24](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/24)
- Redis not mocked in testing [\#18](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/18)
- Scheduled Unique Jobs Not Being Enqueued [\#15](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/15)
- Retries duplicates unique jobs [\#5](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/5)
- Middleware not added to chain? [\#2](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/2)

**Merged pull requests:**

- Make unlock/yield order configurable. [\#21](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/21) ([endofunky](https://github.com/endofunky))
- Rely on Sidekiq's String\#constantize extension instead of rolling our own [\#19](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/19) ([disbelief](https://github.com/disbelief))
- Attempt to constantize String `worker\_class` arguments passed to client middleware [\#17](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/17) ([disbelief](https://github.com/disbelief))
- Compatibility with Sidekiq 2.12.1 Scheduled Jobs [\#16](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/16) ([lsimoneau](https://github.com/lsimoneau))
- Allow worker to specify which arguments to include in uniquing hash [\#12](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/12) ([sax](https://github.com/sax))
- Add support for unique when using Sidekiq's delay function [\#11](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/11) ([eduardosasso](https://github.com/eduardosasso))
- Adding the unique prefix option [\#8](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/8) ([KensoDev](https://github.com/KensoDev))
- Remove unnecessary log messages [\#7](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/7) ([marclennox](https://github.com/marclennox))

## [v2.3.2](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.3.2) (2012-09-27)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.2.1...v2.3.2)

**Closed issues:**

- Scheduled workers [\#1](https://github.com/mhenrixon/sidekiq-unique-jobs/issues/1)

**Merged pull requests:**

- Fix multiple bugs, cleaned up dependencies, and added a feature [\#4](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/4) ([kemper-blinq](https://github.com/kemper-blinq))
- Dependency on sidekiq 2.2.0 and up [\#3](https://github.com/mhenrixon/sidekiq-unique-jobs/pull/3) ([philostler](https://github.com/philostler))

## [v2.2.1](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.2.1) (2012-08-19)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.2.0...v2.2.1)

## [v2.2.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.2.0) (2012-08-19)
[Full Changelog](https://github.com/mhenrixon/sidekiq-unique-jobs/compare/v2.1.0...v2.2.0)

## [v2.1.0](https://github.com/mhenrixon/sidekiq-unique-jobs/tree/v2.1.0) (2012-08-07)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*