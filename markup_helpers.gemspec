# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "markup_helpers/version"

Gem::Specification.new do |s|
  s.name        = "markup_helpers"
  s.version     = MarkupHelpers::VERSION
  s.authors     = ["Macario"]
  s.email       = ["macarui@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Framework agnostic markup helpers}
  s.description = %q{Framework agnostic markup helpers}

  s.rubyforge_project = "markup_helpers"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'erubis'
  s.add_development_dependency 'haml'
  s.add_development_dependency 'tilt'
  s.add_development_dependency 'sinatra'
end
