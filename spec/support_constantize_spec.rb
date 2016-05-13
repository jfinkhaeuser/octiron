require 'spec_helper'
require_relative '../lib/octiron/support/constantize'

class Tester
  include ::Octiron::Support::Constantize
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

describe ::Octiron::Support::Constantize do
  before do
    @tester = Tester.new
  end

  it "throws with an empty path (i.e. '::')" do
    expect do
      @tester.constantize('::')
    end.to raise_error(NameError)
  end

  it "resolves a constant in the global namespace" do
    expect(@tester.constantize('Test')).to eql Test
  end

  it "accepts absolute paths (i.e. starting with '::')" do
    expect(@tester.constantize('::Test')).to eql Test
  end

  it "accepts nested names" do
    expect(@tester.constantize('TestModule::InnerTest')).to \
      eql TestModule::InnerTest
  end

  it "performs lookup in ancestors" do
    expect(@tester.constantize('A::A')).to eql A::A

    expect do
      @tester.constantize('A::does_not_exist')
    end.to raise_error(NameError)

    expect(@tester.constantize('B::B')).to eql B::B
    expect(@tester.constantize('B::A')).to eql A::A

    expect do
      @tester.constantize('B::does_not_exist')
    end.to raise_error(NameError)
  end
end
