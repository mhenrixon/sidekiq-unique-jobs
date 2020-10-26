# gem release [![Build Status](https://secure.travis-ci.org/svenfuchs/gem-release.svg)](http://travis-ci.org/svenfuchs/gem-release)

This gem plugin aims at making gem development easier by automating repetitive work based on conventions, configuration, and templates.

It adds the commands `bootstrap`, `gemspec`, `bump`, `tag` and a `release` to the rubygems `gem` command.

| Project                |  Gem Release |
| ---------------------- | ------------ |
| Gem name               |  gem-release |
| License                |  [MIT](https://github.com/svenfuchs/gem-release/blob/master/LICENSE.md) |
| Version                |  [![Gem Version](https://badge.fury.io/rb/gem-release.svg)](http://badge.fury.io/rb/gem-release) |
| Continuous integration |  [![Build Status](https://secure.travis-ci.org/svenfuchs/gem-release.svg?branch=master)](https://travis-ci.org/svenfuchs/gem-release) |
| Test coverage          |  [![Coverage Status](https://coveralls.io/repos/svenfuchs/gem-release/badge.svg)](https://coveralls.io/r/svenfuchs/gem-release) |
| Documentation          |  [Documentation](http://rdoc.info/github/svenfuchs/gem-release/frames) |
| Credits                |  [Contributors](https://github.com/svenfuchs/gem-release/graphs/contributors) |

# Table of contents

* [Demo](#demo)
* [Installation](#installation)
* [Configuration](#configuration)
* [Conventions](#conventions)
* [Piping](#piping)
* [Reference](#reference)
* [Scenarios](#scenarios)
* [Development](#development)

# Demo

This gif demos some of the things you can do with this plugin:

![gem-release-demo](https://cloud.githubusercontent.com/assets/2208/25634571/68b78080-2f7b-11e7-9eb2-c7d1df13c727.gif)

## Installation

The gem provides a rubygems plugin, so it's just:

```
gem install gem-release
```


# Configuration

Defaults for all options can be specified in a config file at either one of
these locations:

* `~/.gem_release/config.yml`
* `~/.gem_release.yml`
* `./.gem_release/config.yml`
* `./.gem_release.yml`

Config files must be in the [YAML](http://www.yaml.org/) format, and list
options per command. Common options can be set on the root.

For instance, the following entries will set the `quiet` flag for all commands,
and a custom host name with `gem release`:

```yaml
quiet: true

release:
  host: https://example.com
```

Defaults for all options also can be specified as environment variables, for
example `GEM_RELEASE_PRETEND=true`.

Defaults specified in config files and environment variables can be overridden
as command line options when issuing the respective `gem` command.

Only the first config file found in the locations given above will be used, if
any, and defaults from this config file will be merged with both environment
variables and given command line options.


# Conventions

When bootstrapping a new gem:

* A gem name `gem_name` is left untouched when mapped to the path `lib/gem_name`, and the Ruby constant name `GemName`.
* A gem name `gem-name` is mapped to the path `lib/gem/name`, and the Ruby constant name `Gem::Name`

When bumping the version of an existing gem `gem-name` the following locations are checked:

* `lib/gem/name/version.rb`
* `lib/gem-name/version.rb`

# Piping

Output depends on a `tty` being available or not. I.e. when run as an
individual command colorized human readable output will be printed (see the
Demo screencast above). When attached to a pipe then output is kept simple and
parsable.

E.g.:

```
$ gem bump --pretend | cat
bump gem-release 1.0.0 1.0.1
git_add lib/gem/release/version.rb
git_commit "Bump gem-release to 1.0.1"
```

This is useful, for example, for grabbing the next version number:

```
$ gem bump --pretend --no-commit | awk '{ print $4 }'
1.0.1
```


# Reference

The gem `gem-release` adds the following commands to the rubygems `gem` command:

  * [gem bootstrap](#gem-bootstrap) - Scaffolds a new gem from template files.
  * [gem bump](#gem-bump) - Bumps one, several, or all gems in this directory.
  * [gem gemspec](#gem-gemspec) - Generates a gemspec.
  * [gem release](#gem-release) - Releases one or all gems in this directory.
  * [gem tag](#gem-tag) - Tags the HEAD commit with the gem's current version.

## gem bootstrap

Scaffolds a new gem from template files.

### Arguments

```
gem_name - name of the gem (optional, will default to the current directory name if not specified)
```

### Options

```
    --[no-]scaffold              Scaffold gem files (default: true)
    --dir DIR                    Directory to place the gem in (defaults to the given name, or the current working dir)
    --bin                        Create an executable ./bin/[name], add executables directive to .gemspec
-t, --template NAME              Template groups to use for scaffolding
    --rspec                      Use the rspec group (by default adds .rspec and spec/spec_helper.rb)
    --travis                     Use the travis group (by default adds .travis.yml)
-l, --[no-]license NAME          License(s) to add (default: mit)
-s, --strategy NAME              Strategy for collecting files [glob|git] in .gemspec (default: glob)
    --[no-]git                   Initialize a git repo (default: true)
    --github                     Initialize a git repo, create on github
    --remote                     Git remote repository
    --push                       Push the git repo to github
    --[no-]color
    --pretend
```

### Description

Scaffolds a new gem from template files. Optionally initialize a git
repository, set a git remote, and push to the remote repository.

If no argument is given the current directory name is used as the gem
name. If one or many arguments are given then these will be used as
gem names, and new directories will be created accordingly.

By default the following files will be created:

* `.gitignore`
* `Gemspec`
* `[gem-name].gemspec`
* `LICENSE.md`
* `lib/[gem]/[name].rb`
* `lib/[gem]/[name]/version.rb`

Templates in the first existing one of these directories will always
be used to create additional files:

* `./.gem-release/default` (local)
* `~/.gem-release/default` (global)

If `--template [group]` is given additional files will be created from
the first existing one of these directories:

* `./.gem-release/[group]` (local)
* `~/.gem-release/[group]` (global)

It is possible to specify several template groups in order to add
files from several custom template directories.

If `--template rspec` is given then additionally the files `.rspec`
and `spec/spec_helper.rb` will be created, or whatever files exist in
a local or global directory `.gem-release/templates/rspec`.

If `--template travis` is given then additionally the file
`.travis.yml` will be created, or whatever files exist in a local or
global directory `.gem-release/templates/travis`.

The license added by default is the MIT License. If `--license [name]`
is given then this license will be added. The only other license file
shipped is the Mozilla Public License v2.0. Other licenses must be
present in the local or global directory `.gem-release/licenses`. If
`--no-license` is given then no license will be added.

## gem bump

Bumps one, several, or all gems in this directory.

### Arguments

```
gem_name - name of the gem (optional, will use the directory name, or all gemspecs if --recurse is given)
```

### Options

```
-v, --version VERSION            Target version: next [major|minor|patch|pre|release] or a given version number [x.x.x, x.x.x.yyy.z]
-c, --[no-]commit                Create a commit after incrementing gem version (default: true)
-m, --message                    Commit message template (default: Bump %{name} to %{version} %{skip_ci})
    --skip-ci                    Add the [skip ci] tag to the commit message
-p, --push                       Push the new commit to the git remote repository
    --remote REMOTE              Git remote to push to (defaults to origin) (default: origin)
-s, --sign                       GPG sign the commit message
    --branch [BRANCH]            Check out a new branch for the target version (e.g. `v1.0.0`)
-t, --tag                        Shortcut for running the `gem tag` command
-r, --release                    Shortcut for the `gem release` command
    --recurse                    Recurse into directories that contain gemspec files
    --file FILE                  Full path to the version file
    --[no-]color
    --pretend
```

### Description

Bumps the version number defined in lib/[gem_name]/version.rb to to a
given, specific version number, or to the next major, minor, patch, or
pre-release level.

Optionally it pushes to the origin repository. Also, optionally it
invokes the `gem tag` and/or `gem release` command.

If no argument is given the first gemspec's name is assumed as the gem
name. If one or many arguments are given then these will be used as
gem names. If `--recurse` is given then all gem names from all
gemspecs in this directory or any of its subdirectories will be used.

The version can be bumped to either one of these targets:

```
major
1.1.1       # Bump to the given, specific version number
major       # Bump to the next major level (e.g. 0.0.1 to 1.0.0)
minor       # Bump to the next minor level (e.g. 0.0.1 to 0.1.0)
patch       # Bump to the next patch level (e.g. 0.0.1 to 0.0.2)
pre|rc|etc  # Bump to the next pre-release level (e.g. 0.0.1 to
            #   0.1.0.pre.1, 1.0.0.pre.1 to 1.0.0.pre.2)
1.2.0.pre.3 # Bump to specific version number with provided pre-release level and build number
```

When searching for the version file for a gem named `gem-name`: the
following paths will be searched relative to the gemspec's directory.

* `lib/gem-name/version.rb`
* `lib/gem/name/version.rb`

## gem gemspec

Generates a gemspec.

### Arguments

```
gem_name - name of the gem (optional, will default to the current directory name if not specified)
```

### Options

```
    --[no]-bin                   Add bin files directive to the gemspec (defaults to true if a ./bin directory exists)
    --dir DIR                    Directory to place the gem in (defaults to the given name, or the current working dir)
-l, --[no-]license NAMES         License(s) to list in the gemspec
-s, --strategy                   Strategy for collecting files [glob|git] in gemspec (default: glob)
    --[no-]color
    --pretend
```

### Description

Generates a gemspec.

If no argument is given the current directory name is used as the gem
name. If one or many arguments are given then these will be used as
gem names, and new directories will be created accordingly.

The generated `gemspec` file will use the `glob` strategy for finding
files by default. Known strategies are:

* `glob` - uses the glob pattern `{bin/*,lib/**/*,[A-Z]*}`
* `git`  - uses the git command `git ls-files app lib`

## gem release

Releases one or all gems in this directory.

### Arguments

```
gem_name - name of the gem (optional, will use the first gemspec, or all gemspecs if --recurse is given)
```

### Options

```
    --host HOST                  Push to a compatible host other than rubygems.org
-k, --key KEY                    Use the API key from ~/.gem/credentials
-t, --tag                        Shortcut for running the `gem tag` command
-p, --push                       Push tag to the remote git repository
    --recurse                    Recurse into directories that contain gemspec files
    --[no-]color
    --pretend
    --github                     Creates a Release on GitHub. Requires GitHub OAuth token passed by `--token TOKEN`
    --token                      GitHub OAuth token. See https://developer.github.com/v3/#oauth2-token-sent-in-a-header for more details.
```

### Description

Builds one or many gems from the given gemspec(s), pushes them to
rubygems.org (or another, compatible host), and removes the left over
gem file.

Optionally invoke `gem tag`.

If no argument is given the first gemspec's name is assumed as the gem
name. If one or many arguments are given then these will be used. If
`--recurse` is given then all gem names from all gemspecs in this
directory or any of its subdirectories will be used.

## gem tag

Tags the HEAD commit with the gem's current version.

### Options

```
-p, --[no-]push                  Push tag to the remote git repository
    --remote REMOTE              Git remote to push to (default: origin)
-s, --sign                       GPG sign the tag
    --[no-]color
    --pretend
```

### Description

Creates an annotated tag for the current HEAD commit, using the gem's
current version.

Optionally pushes the tag to the origin repository.

If one or many arguments are given then gemspecs with the same names
will be searched, and the working directory changed to their
respective directories. If `--recurse` is given then the directories
all gem names from all gemspecs in this directory or any of its
subdirectories will be used. This assumes that these directories are
separate git repositories.

The tag name will be `v[version]`.  For example, if the current
version is `1.0.0`, then The tag is created using the command `git tag
-am "tag v1.0.0" v1.0.0`.


# Scenarios

* [Single gem in root](#scenario-1-single-gem-in-root)
* [Multiple gems in root](#scenario-2-multiple-gems-in-root)
* [Multiple gems in sub directories](#scenario-3-multiple-gems-in-sub-directories)
* [Nested gem with a conventional sub directory name](#scenario-4-nested-gem-with-a-conventional-sub-directory-name)
* [Nested gem with an irregular sub directory name](#scenario-5-nested-gem-with-an-irregular-sub-directory-name)

## Scenario 1: Single gem in root

### Setup

```
cd /tmp
rm -rf foo
gem bootstrap foo
cd foo
tree -a -I .git
```

### Directory structure

```
.
├── Gemfile
├── LICENSE.md
├── foo.gemspec
└── lib
    ├── foo
    │   └── version.rb
    └── foo.rb
```

### Behaviour

```
# this bumps foo
cd /tmp/foo; gem bump

# this also bumps foo
cd /tmp/foo; gem bump foo
```

### Demo

![gem-release-scenario-1](https://cloud.githubusercontent.com/assets/2208/25634572/68d1fd20-2f7b-11e7-83bc-9e11f60438f3.gif)


## Scenario 2: Multiple gems in root

### Setup

```
cd /tmp
rm -rf foo bar
gem bootstrap foo
cd foo
gem bootstrap bar --dir .
tree -a -I .git
```

### Directory structure

```
.
├── Gemfile
├── LICENSE.md
├── bar.gemspec
├── foo.gemspec
└── lib
    ├── bar
    │   └── version.rb
    ├── bar.rb
    ├── foo
    │   └── version.rb
    └── foo.rb
```

### Behaviour

```
# this bumps both foo and bar
cd /tmp/foo; gem bump --recurse

# this also bumps both foo and bar
cd /tmp/foo; gem bump foo bar

# this bumps foo (because it's the first gemspec found)
cd /tmp/foo; gem bump

# this bumps foo
cd /tmp/foo; gem bump foo

# this bumps bar
cd /tmp/foo; gem bump bar
```

### Demo

![gem-release-scenario-2](https://cloud.githubusercontent.com/assets/2208/25634575/68dcb670-2f7b-11e7-991e-901283164d21.gif)

## Scenario 3: Multiple gems in sub directories

### Setup

```
cd /tmp
rm -rf root
mkdir root
cd root
gem bootstrap foo
gem bootstrap bar
tree -a -I .git
```

### Directory structure

```
.
├── bar
│   ├── Gemfile
│   ├── LICENSE.md
│   ├── bar.gemspec
│   └── lib
│       ├── bar
│       │   └── version.rb
│       └── bar.rb
└── foo
    ├── Gemfile
    ├── LICENSE.md
    ├── foo.gemspec
    └── lib
        ├── foo
        │   └── version.rb
        └── foo.rb
```

### Behaviour

```
# this bumps both foo and bar
cd /tmp/root; gem bump --recurse

# this also bumps both foo and bar
cd /tmp/root; gem bump foo bar

# this does bumps both foo and bar
cd /tmp/root; gem bump

# this bumps foo
cd /tmp/root; gem bump foo

# this bumps bar
cd /tmp/root; gem bump bar
```

### Demo

![gem-release-scenario-3](https://cloud.githubusercontent.com/assets/2208/25634573/68d51c3a-2f7b-11e7-8ec8-629bc8019d16.gif)


## Scenario 4: Nested gem with a conventional sub directory name

### Setup

```
cd /tmp
rm -rf sinja
gem bootstrap sinja
cd sinja
mkdir extensions
cd extensions
gem bootstrap sinja-sequel
cd /tmp/sinja
tree -a -I .git
```

### Directory structure

```
.
├── Gemfile
├── LICENSE.md
├── extensions
│   └── sinja-sequel
│       ├── Gemfile
│       ├── LICENSE.md
│       ├── lib
│       │   └── sinja
│       │       ├── sequel
│       │       │   └── version.rb
│       │       └── sequel.rb
│       └── sinja-sequel.gemspec
├── lib
│   ├── sinja
│   │   └── version.rb
│   └── sinja.rb
└── sinja.gemspec
```

### Behaviour

```
# this bumps both sinja and sinja-sequel
cd /tmp/sinja; gem bump --recurse

# this bumps sinja
cd /tmp/sinja; gem bump

# this also bumps sinja
cd /tmp/sinja; gem bump sinja

# this bumps sinja-sequel
cd /tmp/sinja; gem bump sinja-sequel

# this also bumps sinja-sequel
cd /tmp/sinja/extensions/sinja-sequel; gem bump

# this also bumps sinja-sequel
cd /tmp/sinja/extensions/sinja-sequel; gem bump sinja-sequel
```

### Demo

![gem-release-scenario-4](https://cloud.githubusercontent.com/assets/2208/25634576/68dce4a6-2f7b-11e7-9d6b-571d672e4998.gif)

## Scenario 5: Nested gem with an irregular sub directory name

### Setup

```
cd /tmp
rm -rf sinja
gem bootstrap sinja
cd sinja
mkdir -p extensions
cd extensions
gem bootstrap sinja-sequel
mv sinja-sequel sequel
cd /tmp/sinja
tree -a -I .git
```

### Directory structure

```
.
├── Gemfile
├── LICENSE.md
├── extensions
│   └── sequel
│       ├── Gemfile
│       ├── LICENSE.md
│       ├── lib
│       │   └── sinja
│       │       ├── sequel
│       │       │   └── version.rb
│       │       └── sequel.rb
│       └── sinja-sequel.gemspec
├── lib
│   ├── sinja
│   │   └── version.rb
│   └── sinja.rb
└── sinja.gemspec
```

### Behaviour

```
# this bumps both sinja and sinja-sequel
cd /tmp/sinja; gem bump --recurse

# this bumps sinja
cd /tmp/sinja; gem bump

# this also bumps sinja
cd /tmp/sinja; gem bump sinja

# this bumps sinja-sequel only
cd /tmp/sinja; gem bump sinja-sequel

# this also bumps sinja-sequel only
cd /tmp/sinja/extensions/sequel; gem bump

# this also bumps sinja-sequel only
cd /tmp/sinja/extensions/sequel; gem bump sinja-sequel
```

### Demo

![gem-release-scenario-5](https://cloud.githubusercontent.com/assets/2208/25634574/68d6d138-2f7b-11e7-9e64-e4c86cb85b9a.gif)


# Development

Running tests:

```
bundle install
bundle exec rspec
```

Testing commands against a [Geminabox](https://github.com/geminabox/geminabox) instance:

```
# start geminabox
bundle install
bundle exec rackup

# workaround rubygems issue with a missing key
# see https://github.com/geminabox/geminabox/issues/153
echo ':localhost: none' >> ~/.gem/credentials

# test release
bundle exec gem release --host=http://localhost:9292 --key localhost
```

