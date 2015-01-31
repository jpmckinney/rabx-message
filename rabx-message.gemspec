# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rabx/message/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "rabx-message"
  s.version     = RABX::Message::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James McKinney"]
  s.homepage    = "https://github.com/jpmckinney/rabx-message"
  s.summary     = %q{A RPC using Anything But XML (RABX) message parser and emitter}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('netstring', '~> 0.0')

  s.add_development_dependency('coveralls')
  s.add_development_dependency('json', '~> 1.8') # to silence coveralls warning
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 3.1')
end
