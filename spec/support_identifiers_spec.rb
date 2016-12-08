require 'spec_helper'
require_relative '../lib/octiron/support/identifiers'

class Tester
  include ::Octiron::Support::Identifiers

  def initialize(*_)
    @default_namespace = 'Octiron::Support'
  end
end

class Test
end

module TestModule
  class InnerTest
  end
end

class A
  class A
  end
end

class B < A
  class B
  end
end

describe ::Octiron::Support::Identifiers do
  before do
    @tester = Tester.new
  end

  it "throws with an empty path (i.e. '::')" do
    expect do
      @tester.identify('::')
    end.to raise_error(NameError)

    expect do
      @tester.identify('')
    end.to raise_error(NameError)

    expect do
      @tester.identify(nil)
    end.to raise_error(NameError)
  end

  it "returns the name of a Class" do
    expect(@tester.identify(Test)).to eql 'Test'
    expect(@tester.identify(A)).to eql 'A'
    expect(@tester.identify(B)).to eql 'B'
  end

  it "returns Hashes untouched" do
    test_hash = {}
    expect(@tester.identify(test_hash)).to eql test_hash
    expect(@tester.identify(test_hash).object_id).to eql test_hash.object_id
  end

  it "resolves strings to constant names" do
    expect(@tester.identify('Octiron::Support::Identifiers')).to eql \
      'Octiron::Support::Identifiers'
  end

  it "attempts to resolve anything else as constants in the default namespace" do
    expect(@tester.identify(:identifiers)).to eql \
      'Octiron::Support::Identifiers'
  end
end
