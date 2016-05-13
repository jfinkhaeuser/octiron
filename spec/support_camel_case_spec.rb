require 'spec_helper'
require_relative '../lib/octiron/support/camel_case'

class Tester
  include ::Octiron::Support::CamelCase
end

describe ::Octiron::Support::CamelCase do
  before do
    @tester = Tester.new
  end

  it "capitalizes a single word" do
    expect(@tester.camel_case('foo')).to eql 'Foo'
  end

  it "capitalizes letters in underscore separated words" do
    expect(@tester.camel_case('foo_bar')).to eql 'FooBar'
  end

  it "handles symbols" do
    expect(@tester.camel_case(:foo_bar)).to eql 'FooBar'
  end
end
