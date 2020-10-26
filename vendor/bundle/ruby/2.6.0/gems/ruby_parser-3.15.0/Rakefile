# -*- ruby -*-

require "rubygems"
require "hoe"

Hoe.plugin :seattlerb
Hoe.plugin :racc
Hoe.plugin :isolate
Hoe.plugin :rdoc

Hoe.add_include_dirs "lib"
Hoe.add_include_dirs "../../sexp_processor/dev/lib"
Hoe.add_include_dirs "../../minitest/dev/lib"
Hoe.add_include_dirs "../../oedipus_lex/dev/lib"

V2   = %w[20 21 22 23 24 25 26 27]
V2.replace [V2.last] if ENV["FAST"] # HACK

Hoe.spec "ruby_parser" do
  developer "Ryan Davis", "ryand-ruby@zenspider.com"

  license "MIT"

  dependency "sexp_processor", "~> 4.9"
  dependency "rake", "< 11", :developer
  dependency "oedipus_lex", "~> 2.5", :developer

  require_ruby_version [">= 2.1", "< 3.1"]

  if plugin? :perforce then     # generated files
    V2.each do |n|
      self.perforce_ignore << "lib/ruby#{n}_parser.rb"
    end

    V2.each do |n|
      self.perforce_ignore << "lib/ruby#{n}_parser.y"
    end

    self.perforce_ignore << "lib/ruby_lexer.rex.rb"
  end

  if plugin?(:racc)
    self.racc_flags << " -t" if ENV["DEBUG"]
    self.racc_flags << " --superclass RubyParser::Parser"
    # self.racc_flags << " --runtime ruby_parser" # TODO: broken in racc
  end
end

V2.each do |n|
  file "lib/ruby#{n}_parser.y" => "lib/ruby_parser.yy" do |t|
    cmd = 'unifdef -tk -DV=%s -UDEAD %s > %s || true' % [n, t.source, t.name]
    sh cmd
  end

  file "lib/ruby#{n}_parser.rb" => "lib/ruby#{n}_parser.y"
end

file "lib/ruby_lexer.rex.rb" => "lib/ruby_lexer.rex"

task :generate => [:lexer, :parser]

task :clean do
  rm_rf(Dir["**/*~"] +
        Dir["diff.diff"] + # not all diffs. bit me too many times
        Dir["coverage.info"] +
        Dir["coverage"] +
        Dir["lib/ruby2*_parser.y"] +
        Dir["lib/*.output"])
end

task :sort do
  sh "grepsort '^ +def' lib/ruby_lexer.rb"
  sh "grepsort '^ +def (test|util)' test/test_ruby_lexer.rb"
end

desc "what was that command again?"
task :huh? do
  puts "ruby #{Hoe::RUBY_FLAGS} bin/ruby_parse -q -g ..."
end

def (task(:phony)).timestamp
  Time.at 0
end

task :isolate => :phony

def in_compare
  Dir.chdir "compare" do
    yield
  end
end

def dl v
  dir = v[/^\d+\.\d+/]
  url = "https://cache.ruby-lang.org/pub/ruby/#{dir}/ruby-#{v}.tar.bz2"
  path = File.basename url
  unless File.exist? path then
    system "curl -O #{url}"
  end
end

def ruby_parse version
  v         = version[/^\d+\.\d+/].delete "."
  rp_txt    = "rp#{v}.txt"
  mri_txt   = "mri#{v}.txt"
  parse_y   = "parse#{v}.y"
  tarball   = "ruby-#{version}.tar.bz2"
  ruby_dir  = "ruby-#{version}"
  diff      = "diff#{v}.diff"
  rp_out    = "lib/ruby#{v}_parser.output"
  _rp_y     = "lib/ruby#{v}_parser.y"
  rp_y_rb   = "lib/ruby#{v}_parser.rb"

  c_diff    = "compare/#{diff}"
  c_rp_txt  = "compare/#{rp_txt}"
  c_mri_txt = "compare/#{mri_txt}"
  c_parse_y = "compare/#{parse_y}"
  c_tarball = "compare/#{tarball}"
  normalize = "compare/normalize.rb"

  file c_tarball do
    in_compare do
      dl version
    end
  end

  file c_parse_y => c_tarball do
    in_compare do
      extract_glob = case version
                     when /2\.7/
                       "{id.h,parse.y,tool/{id2token.rb,lib/vpath.rb}}"
                     else
                       "{id.h,parse.y,tool/{id2token.rb,vpath.rb}}"
                     end
      system "tar yxf #{tarball} #{ruby_dir}/#{extract_glob}"

      Dir.chdir ruby_dir do
        if File.exist? "tool/id2token.rb" then
          sh "ruby tool/id2token.rb --path-separator=.:./ id.h parse.y | expand > ../#{parse_y}"
        else
          sh "expand parse.y > ../#{parse_y}"
        end

        ruby "-pi", "-e", 'gsub(/^%define\s+api\.pure/, "%pure-parser")', "../#{parse_y}"
      end
      sh "rm -rf #{ruby_dir}"
    end
  end

  file c_mri_txt => [c_parse_y, normalize] do
    in_compare do
      sh "bison -r all #{parse_y}"
      sh "./normalize.rb parse#{v}.output > #{mri_txt}"
      rm ["parse#{v}.output", "parse#{v}.tab.c"]
    end
  end

  file rp_out => rp_y_rb

  file c_rp_txt => [rp_out, normalize] do
    in_compare do
      sh "./normalize.rb ../#{rp_out} > #{rp_txt}"
    end
  end

  compare = "compare#{v}"

  desc "Compare all grammars to MRI"
  task :compare => compare

  file c_diff => [c_mri_txt, c_rp_txt] do
    in_compare do
      sh "diff -du #{mri_txt} #{rp_txt} > #{diff}; true"
    end
  end

  desc "Compare #{v} grammar to MRI #{version}"
  task compare => c_diff do
    in_compare do
      system "wc -l #{diff}"
    end
  end

  task :clean do
    rm_f Dir[c_mri_txt, c_rp_txt]
  end

  task :realclean do
    rm_f Dir[c_parse_y, tarball]
  end
end

ruby_parse "2.0.0-p648"
ruby_parse "2.1.9"
ruby_parse "2.2.9"
ruby_parse "2.3.8"
ruby_parse "2.4.9"
ruby_parse "2.5.8"
ruby_parse "2.6.6"
ruby_parse "2.7.1"

task :debug => :isolate do
  ENV["V"] ||= V2.last
  Rake.application[:parser].invoke # this way we can have DEBUG set
  Rake.application[:lexer].invoke # this way we can have DEBUG set

  $:.unshift "lib"
  require "ruby_parser"
  require "pp"

  klass = Object.const_get("Ruby#{ENV["V"]}Parser") rescue nil
  raise "Unsupported version #{ENV["V"]}" unless klass
  parser = klass.new

  time = (ENV["RP_TIMEOUT"] || 10).to_i

  n = ENV["BUG"]
  file = (n && "bug#{n}.rb") || ENV["F"] || ENV["FILE"] || "bug.rb"
  ruby = ENV["R"] || ENV["RUBY"]

  if ruby then
    file = "env"
  else
    ruby = File.read file
  end


  begin
    pp parser.process(ruby, file, time)
  rescue ArgumentError, Racc::ParseError => e
    p e
    puts e.backtrace.join "\n  "
    ss = parser.lexer.ss
    src = ss.string
    lines = src[0..ss.pos].split(/\n/)
    abort "on #{file}:#{lines.size}"
  end
end

task :debug3 do
  file    = ENV["F"] || "bug.rb"
  verbose = ENV["V"] ? "-v" : ""
  munge    = "./tools/munge.rb #{verbose}"

  abort "Need a file to parse, via: F=path.rb" unless file

  ENV.delete "V"

  sh "ruby -v"
  sh "ruby -y #{file} 2>&1 | #{munge} > tmp/ruby"
  sh "./tools/ripper.rb -d #{file} | #{munge} > tmp/rip"
  sh "rake debug F=#{file} DEBUG=1 2>&1 | #{munge} > tmp/rp"
  sh "diff -U 999 -d tmp/{rip,rp}"
end

task :cmp do
  sh %(emacsclient --eval '(ediff-files "tmp/ruby" "tmp/rp")')
end

task :cmp3 do
  sh %(emacsclient --eval '(ediff-files3 "tmp/ruby" "tmp/rip" "tmp/rp")')
end

task :extract => :isolate do
  ENV["V"] ||= V2.last
  Rake.application[:parser].invoke # this way we can have DEBUG set

  file = ENV["F"] || ENV["FILE"]

  ruby "-Ilib", "bin/ruby_parse_extract_error", file
end

task :bugs do
  sh "for f in bug*.rb ; do #{Gem.ruby} -S rake debug F=$f && rm $f ; done"
end

# vim: syntax=Ruby
