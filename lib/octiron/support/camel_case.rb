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
  # @see CamelCase::camel_case
  module CamelCase

    ##
    # Takes an underscored name and turns it into a CamelCase String
    # @param underscored_name (String, Symbol) the underscored name to turn
    #     into camel case.
    # @return (String) CamelCased version of the underscored_name
    def camel_case(underscored_name)
      return underscored_name.to_s.split("_").map do |word|
        word.upcase[0] + word[1..-1]
      end.join
    end

  end # module CamelCase
end # module Octiron::Support
