require 'spec_helper'
require_relative '../lib/octiron/world'

class Test1
end

class Test2
end

describe Octiron::World do
  before :each do
    @tester = Class.new
    @tester.extend(Octiron::World)
  end

  describe "singletons" do
    it "has a transmogrifier registry" do
      Octiron::World.respond_to?(:transmogrifier_registry)
    end

    it "has a singleton transmogrifier registry" do
      expect(Octiron::World.transmogrifier_registry.object_id).to eql\
          Octiron::World.transmogrifier_registry.object_id
    end

    it "has an event bus" do
      Octiron::World.respond_to?(:event_bus)
    end

    it "has a singleton event bus" do
      expect(Octiron::World.event_bus.object_id).to eql\
          Octiron::World.event_bus.object_id
    end
  end

  describe "event bus" do
    it "uses on_event/publish to hide API complexity" do
      invoked = 0
      @tester.on_event(Test1) do |_|
        invoked += 1
      end

      @tester.publish(Test1.new)
      expect(invoked).to eql 1
    end
  end

  describe "transmogrifier registry" do
    it "uses on_transmogrify/transmogrify to hide API complexity" do
      @tester.on_transmogrify(Test1).to Test2 do |_|
        next Test2.new
      end

      result = @tester.transmogrify(Test1.new).to Test2
      expect(result.class).to eql Test2
    end
  end
end
