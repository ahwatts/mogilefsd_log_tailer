# -*- encoding: utf-8; mode: ruby -*-
$:.push File.expand_path("../lib", __FILE__)
require "mogilefsd_log_tailer/version"

Gem::Specification.new do |s|
  s.name        = "mogilefsd_log_tailer"
  s.version     = MogilefsdLogTailer::VERSION
  s.authors     = ["Andrew Watts"]
  s.email       = ["ahwatts@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "mogilefsd_log_tailer"

  s.add_dependency('eventmachine')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
