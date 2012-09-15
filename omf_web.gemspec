# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omf-web/version"

Gem::Specification.new do |s|
  s.name        = "omf_web"
#  s.version     = OmfWeb::VERSION
  s.version     = '0.9.1'
  s.authors     = ["NICTA"]
  s.email       = ["omf-user@lists.nicta.com.au"]
  s.homepage    = "https://www.mytestbed.net"
  s.summary     = %q{OMF's web frontend.}
  s.description = %q{OMF's Web based control and visualization framework.}

  s.rubyforge_project = "omf_web"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
#  s.add_development_dependency "minitest", "~> 2.11.3"
  s.add_runtime_dependency "erector", "~> 0.8.3"
  s.add_runtime_dependency "activesupport", "~> 3.0.0" # required by erector:table
  s.add_runtime_dependency "rack", "~> 1.3.5"
  s.add_runtime_dependency "thin", "~> 1.3.1"
  s.add_runtime_dependency "coderay", "~> 1.0.6"
  s.add_runtime_dependency "log4r", "~> 1.1.10"
  s.add_runtime_dependency "maruku", "~> 0.6.0"
  s.add_runtime_dependency "ritex", "~> 1.0.1"
  s.add_runtime_dependency "json", "~> 1.7.3"
  s.add_runtime_dependency "grit", "~> 2.5.0"
  s.add_runtime_dependency "sqlite3", "~> 1.3.6"
end
