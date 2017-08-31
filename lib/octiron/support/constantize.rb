# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016-2017 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

module Octiron::Support
  ##
  # @see Constantize::constantize
  module Constantize

    ##
    # Takes a String containing a constant name, and returns the canonical path
    # of the constant (i.e. where it's defined, even if it's accessed
    # differently.). If the constant does not exist, a NameError is thrown.
    # @param constant_name (String) the constant name
    # @return (Object) the actual named constant.
    def constantize(constant_name)
      names = constant_name.split('::')

      # Trigger a built-in NameError exception including the ill-formed
      # constant in the message.
      if names.empty?
        Object.const_get(constant_name, false)
      end

      # Remove the first blank element in case of '::ClassName' notation.
      if names.size > 1 && names.first.empty?
        names.shift
      end

      # Note: this would be much more complex in Ruby < 1.9.3, so yay for not
      # bothering to support these!
      return names.inject(Object) do |constant, name|
        next constant.const_get(name)
      end
    end

  end # module Constantize
end # module Octiron::Support
