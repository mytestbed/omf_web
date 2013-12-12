# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omf-web/version"

Gem::Specification.new do |s|
  s.name        = "omf_web"
  s.version     = OMF::Web::VERSION
  s.authors     = ["NICTA"]
  s.email       = ["omf-user@lists.nicta.com.au"]
  s.homepage    = "https://www.mytestbed.net"
  s.summary     = %q{OMF's web frontend.}
  s.description = %q{OMF's Web based control and visualization framework.}
  s.license
  s.rubyforge_project = "omf_web"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- {bin,sbin}/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
#  s.add_development_dependency "minitest", "~> 2.11.3"
  s.add_runtime_dependency "omf_oml", "~> 1.0"
  s.add_runtime_dependency "omf_base"
  s.add_runtime_dependency "erector", "~> 0.9.0"
  s.add_runtime_dependency "activesupport", "~> 3.0.0" # required by erector:table
  s.add_runtime_dependency "rack", "~> 1.0"
  s.add_runtime_dependency "thin", "~> 1.0"
  s.add_runtime_dependency "coderay", "~> 1.0"
  s.add_runtime_dependency "maruku", "~> 0.6.0"
  s.add_runtime_dependency "ritex", "~> 1.0.0"
  s.add_runtime_dependency "json", "~> 1.7.0"
  s.add_runtime_dependency "grit", "~> 2.5.0"
  s.add_runtime_dependency "websocket-rack", "~> 0.4.0"
  s.add_runtime_dependency "rack-accept", "~> 0.4.0"
  s.add_runtime_dependency "i18n"

  # Do we need the next two dependencies?
  #s.add_runtime_dependency "sqlite3", "~> 1.3.6"
  #s.add_runtime_dependency "postgres-pr", "~> 0.6.3"

  s.add_runtime_dependency "ruby-openid", "~> 2.2.3"

end
