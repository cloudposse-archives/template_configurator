# -*- encoding: utf-8 -*-
require File.expand_path('../lib/template_configurator/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Erik Osterman"]
  gem.email         = ["e@osterman.com"]
  gem.summary       = %q{Template Configurator is a utility to write configuration files from ERB templates.}
  gem.description   = %q{Template Configurator is a utility to write configuration files from ERB templates. When the file's content changes, it can then call an init script to intelligently reload the configuration. Through out the entire process exclusive file locks are used on the output file and json file to help ensure they are unmanipulated during the transformation process.}
  gem.homepage      = "https://github.com/osterman/template_configurator"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "template_configurator"
  gem.require_paths = ["lib"]
  gem.version       = TemplateConfigurator::VERSION
  gem.add_runtime_dependency 'json', '>= 1.4.3'
end
