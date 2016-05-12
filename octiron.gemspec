# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'octiron/version'

# rubocop:disable Style/UnneededPercentQ, Style/ExtraSpacing
# rubocop:disable Style/SpaceAroundOperators
Gem::Specification.new do |spec|
  spec.name          = "octiron"
  spec.version       = Octiron::VERSION
  spec.authors       = ["Jens Finkhaeuser"]
  spec.email         = ["jens@finkhaeuser.de"]
  spec.description   = %q(
    Events octiron responds to can be any classes or Hash prototypes. Using
    transmogrifiers, events can be turned into other kinds of events.

    GitHub "events" are API calls to GitHub that modify something, e.g. create
    or delete issues, comments, etc.

    The gem includes some transmogrifiers that transmogrify Hash events to
    GitHub API calls via octokit.

    Users neet to provide some GitHub authentication information, and
    transmogrifiers from their own bespoke events to Hash events, and octiron
    takes care of turning this into GitHub API calls.
  )
  spec.summary       = %q(
    Octiron magically transforms events to GitHub "events".
  )
  spec.homepage      = "https://github.com/jfinkhaeuser/octiron"
  spec.license       = "MITNFA"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rubocop", "~> 0.40"
  spec.add_development_dependency "rake", "~> 11.1"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "simplecov", "~> 0.11"
  spec.add_development_dependency "yard", "~> 0.8"

  spec.add_dependency "octokit", "~> 4.3"
end
# rubocop:enable Style/SpaceAroundOperators
# rubocop:enable Style/UnneededPercentQ, Style/ExtraSpacing
