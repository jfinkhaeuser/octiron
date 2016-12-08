# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

require_relative 'camel_case'
require_relative 'constantize'

module Octiron::Support
  ##
  # @see Identifiers::identify
  module Identifiers
    include ::Octiron::Support::CamelCase
    include ::Octiron::Support::Constantize

    ##
    # This function "identifies" an object, i.e. returns a unique ID according
    # to the octiron logic. That means that:
    # - For classes, a stringified version is returned
    # - For hashes, the hash itself is returned
    # - Strings are interpreted as constant names, and are returned fully
    #   qualified.
    # - Everything else is considered to be a constant name in the default
    #   namespace. This requires access to a @default_namespace variable in
    #   the including class.
    def identify(name)
      case name
      when Class
        return name.to_s
      when Hash
        return name
      when String
        return constantize(name).to_s
      else
        return constantize("#{@default_namespace}::#{camel_case(name)}").to_s
      end
    end
  end # module Identifiers
end # module Octiron::Support
