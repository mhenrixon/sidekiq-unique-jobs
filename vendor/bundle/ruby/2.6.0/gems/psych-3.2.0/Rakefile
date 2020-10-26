require "bundler"
Bundler::GemHelper.install_tasks

require "rake/testtask"
Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/test_*.rb']
  t.verbose = true
  t.warning = true
end

if RUBY_PLATFORM =~ /java/
  require 'rake/javaextensiontask'
  Rake::JavaExtensionTask.new("psych") do |ext|
    require 'maven/ruby/maven'
    # force load of versions to overwrite constants with values from repo.
    load './lib/psych/versions.rb'
    # uses Mavenfile to write classpath into pkg/classpath
    # and tell maven via system properties the snakeyaml version
    # this is basically the same as running from the commandline:
    # rmvn dependency:build-classpath -Dsnakeyaml.version='use version from Psych::DEFAULT_SNAKEYAML_VERSION here'
    Maven::Ruby::Maven.new.exec('dependency:build-classpath', "-Dsnakeyaml.version=#{Psych::DEFAULT_SNAKEYAML_VERSION}", '-Dverbose=true')
    ext.source_version = '1.7'
    ext.target_version = '1.7'
    ext.classpath = File.read('pkg/classpath')
    ext.ext_dir = 'ext/java'
  end
else
  require 'rake/extensiontask'
  Rake::ExtensionTask.new("psych")
end

task :default => [:compile, :test]
