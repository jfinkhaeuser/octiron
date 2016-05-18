require 'spec_helper'
require_relative '../lib/octiron/transmogrifiers/registry'

class Test1
end

class Test2
end

class Test3
end

class Transmogrifier
  attr_reader :invoked
  def initialize
    @invoked = 0
  end

  def call(_)
    @invoked += 1
  end
end

class Test1To2Transmogrifier < Transmogrifier
  def call(from)
    super
    return Test2.new
  end
end

class Test2To3Transmogrifier < Transmogrifier
  def call(from)
    super
    return Test3.new
  end
end

class Test1To3Transmogrifier < Transmogrifier
  def call(from)
    super
    return Test3.new
  end
end

describe Octiron::Transmogrifiers::Registry do
  describe "construction" do
    it "can be constructed without a default namespace" do
      reg = nil
      expect do
        reg = ::Octiron::Transmogrifiers::Registry.new
      end.not_to raise_error

      expect(reg.default_namespace).to eql 'Octiron::Transmogrifiers'
    end

    it "can be constructed with a namespace" do
      reg = nil
      expect do
        reg = ::Octiron::Transmogrifiers::Registry.new(::Octiron::Transmogrifiers)
      end.not_to raise_error

      expect(reg.default_namespace).to eql 'Octiron::Transmogrifiers'
    end
  end

  describe "registration" do
    before :each do
      @reg = ::Octiron::Transmogrifiers::Registry.new
    end

    it "can register a transmogrifier object" do
      expect do
        @reg.register(Test1, Test2, false, Transmogrifier.new)
      end.not_to raise_error
    end

    it "throws when registering a transmogrifier for the same pair twice" do
      expect do
        @reg.register(Test1, Test2, false, Transmogrifier.new)
      end.not_to raise_error

      expect do
        @reg.register(Test1, Test2, false, Transmogrifier.new)
      end.to raise_error(ArgumentError)
    end

    it "can overwrite transmogrifiers" do
      expect do
        @reg.register(Test1, Test2, false, Transmogrifier.new)
      end.not_to raise_error

      expect do
        @reg.register(Test1, Test2, true, Transmogrifier.new)
      end.not_to raise_error
    end

    it "can register transmogrifier procs" do
      expect do
        @reg.register(Test1, Test2) do |_|
        end
      end.not_to raise_error
    end

    it "raises if no transmogrifier is given" do
      expect do
        @reg.register(Test1, Test2)
      end.to raise_error(ArgumentError)

      expect do
        @reg.register(Test1, Test2, false)
      end.to raise_error(ArgumentError)
    end

    it "can deregister a transmogrifier" do
      expect do
        @reg.register(Test1, Test2) do |_|
        end
      end.not_to raise_error

      # First time, there is a transmogrifier
      expect do
        @reg.deregister(Test1, Test2)
      end.not_to raise_error

      # Second time, there is none - it still shouldn't fail
      expect do
        @reg.deregister(Test1, Test2)
      end.not_to raise_error
    end
  end

  describe "register argument validation" do
    before :each do
      @reg = ::Octiron::Transmogrifiers::Registry.new
    end

    it "accepts string names" do
      expect do
        @reg.register('Test1', 'Test2', false, Transmogrifier.new)
      end.not_to raise_error
    end

    it "accepts symbol names" do
      expect do
        @reg.register(:test1, :test2, false, Transmogrifier.new)
      end.not_to raise_error
    end
  end

  describe "transmogrification" do
    before :each do
      @reg = ::Octiron::Transmogrifiers::Registry.new
      @trans1to2 = Test1To2Transmogrifier.new
      @trans2to3 = Test2To3Transmogrifier.new
      @reg.register(Test1, Test2, false, @trans1to2)
      @reg.register(Test2, Test3, false, @trans2to3)
    end

    it "can transmogrify with a directly registered transmogrifier" do
      result = nil

      expect do
        result = @reg.transmogrify(Test1.new, Test2)
      end.not_to raise_error

      expect(result.class).to eql Test2

      expect(@trans1to2.invoked).to eql 1
      expect(@trans2to3.invoked).to eql 0
    end

    it "can transmogrify with indirectly registered transmogrifiers" do
      result = nil

      expect do
        result = @reg.transmogrify(Test1.new, Test3)
      end.not_to raise_error

      expect(result.class).to eql Test3

      expect(@trans1to2.invoked).to eql 1
      expect(@trans2to3.invoked).to eql 1
    end

    it "chooses the shortest transmogrification path" do
      result = nil

      direct = Test1To3Transmogrifier.new
      @reg.register(Test1, Test3, false, direct)

      expect do
        result = @reg.transmogrify(Test1.new, Test3)
      end.not_to raise_error

      expect(result.class).to eql Test3

      expect(@trans1to2.invoked).to eql 0
      expect(@trans2to3.invoked).to eql 0
      expect(direct.invoked).to eql 1
    end

    it "fails if no transmogrifier is found" do
      expect do
        @reg.transmogrify(Test1.new, Hash)
      end.to raise_error(ArgumentError)
    end

    it "fails if a transmogrifier misbehaves" do
      # Register the wrong 'direct' transmogrifier that will then be chosen
      direct = Test1To2Transmogrifier.new
      @reg.register(Test1, Test3, false, direct)

      expect do
        @reg.transmogrify(Test1.new, Test3)
      end.to raise_error(RuntimeError)
    end
  end
end
