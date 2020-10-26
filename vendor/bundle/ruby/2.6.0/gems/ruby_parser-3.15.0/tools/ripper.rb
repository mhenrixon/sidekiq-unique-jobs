#!/usr/bin/env ruby -ws

$d ||= false
$p ||= false

require "ripper/sexp"
require "pp" if $p

if ARGV.empty? then
  warn "reading from stdin"
  ARGV << "-"
end

class MySexpBuilder < Ripper::SexpBuilderPP
  def on_parse_error msg
    Kernel.warn msg
  end
end

ARGV.each do |path|
  src = path == "-" ? $stdin.read : File.read(path)
  rip = MySexpBuilder.new src
  rip.yydebug = $d

  sexp = rip.parse

  if rip.error? then
    warn "skipping"
    next
  end

  puts "accept"

  if $p then
    pp sexp
  else
    p sexp
  end
end
