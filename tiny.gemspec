# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require "tiny/version"

Gem::Specification.new do |s|
  s.name        = "tiny"
  s.version     = Tiny::VERSION
  s.authors     = ["Macario"]
  s.email       = ["macarui@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Framework agnostic markup builder, useful for building view helpers or as a micro templating dsl, plays nice with erb and haml}
  s.description = %q{Tiny is a tiny framework agnostic markup builder, useful for building view helpers on inclusion only adds three public methods, tag (for generating html tags), capture and concat, works as pure ruby and with erb and haml}

  s.rubyforge_project = "tiny"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'tilt'
  s.add_runtime_dependency 'escape_utils'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'erubis'
  s.add_development_dependency 'haml'
  s.add_development_dependency 'tilt'
  s.add_development_dependency 'sinatra'
  s.add_development_dependency 'rails'
end
