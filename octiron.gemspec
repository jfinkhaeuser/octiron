# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016-2018 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'octiron/version'

# rubocop:disable Style/UnneededPercentQ, Layout/ExtraSpacing
# rubocop:disable Layout/SpaceAroundOperators
Gem::Specification.new do |spec|
  spec.name          = "octiron"
  spec.version       = Octiron::VERSION
  spec.authors       = ["Jens Finkhaeuser"]
  spec.email         = ["jens@finkhaeuser.de"]
  spec.description   = %q(
    Events octiron responds to can be any classes or Hash prototypes. Using
    transmogrifiers, events can be turned into other kinds of events
    transparently.
  )
  spec.summary       = %q(
    Octiron is an event bus with the ability to magically transform events.
  )
  spec.homepage      = "https://github.com/jfinkhaeuser/octiron"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 11.3"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "yard", "~> 0.9", ">= 0.9.12"

  spec.add_dependency "collapsium", "~> 0.10"
  spec.add_dependency "rgl", "~> 0.5"
end
# rubocop:enable Layout/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ, Layout/ExtraSpacing
