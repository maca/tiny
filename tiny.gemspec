# encoding: utf-8
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "tiny/version"

Gem::Specification.new do |s|
  s.name        = "tiny"
  s.version     = Tiny::VERSION
  s.authors     = ["Macario"]
  s.email       = ["macarui@gmail.com"]
  s.homepage    = "https://github.com/maca/tiny"
  s.summary     = 'Framework agnostic markup builder, useful for building view helpers or as a micro templating dsl, plays nice with erb and haml'
  s.description = 'Tiny is a tiny framework agnostic markup builder, useful for building view helpers on inclusion only adds three public methods, tag (for generating html tags), capture and concat, works as pure ruby and with erb and haml'

  s.rubyforge_project = "tiny"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'tilt'
  s.add_runtime_dependency 'erubis'

  s.add_development_dependency 'rspec', '~> 3.7.0'
  s.add_development_dependency 'capybara', '~> 3.2.1'
  s.add_development_dependency 'haml', '~> 5.0.4'
  s.add_development_dependency 'sinatra', '~> 2.0.3'
  s.add_development_dependency 'rails', '~> 5.2.0'
end
