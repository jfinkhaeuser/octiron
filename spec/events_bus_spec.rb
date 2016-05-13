require 'spec_helper'
require_relative '../lib/octiron/events/bus'

class TestEvent
end

module TestModule
  class InnerTestEvent
  end
end


class TestHandler
  attr_reader :invoked, :event

  def initialize
    @invoked = false
    @event = nil
  end

  def call(event)
    @event = event
    @invoked = true
  end
end

describe Octiron::Events::Bus do
  describe "construction" do
    it "cannot be constructed without a default namespace" do
      expect do
        ::Octiron::Events::Bus.new
      end.to raise_error(ArgumentError)
    end

    it "can be constructed with a namespace" do
      expect do
        ::Octiron::Events::Bus.new(::Octiron::Events)
      end.not_to raise_error
    end
  end

  describe "registration" do
    before :each do
      @bus = ::Octiron::Events::Bus.new(::Octiron::Events)
    end

    it "requires a handler" do
      expect do
        klass = @bus.register(TestEvent)
      end.to raise_error(ArgumentError)
    end

    it "can register an object handler for an event" do
      klass = nil
      expect do
        klass = @bus.register(TestEvent, TestHandler.new)
      end.not_to raise_error
      expect(klass).to eql TestEvent
    end

    it "can register a handler proc for an event" do
      klass = nil
      expect do
        klass = @bus.register(TestEvent) do |_|
        end
      end.not_to raise_error
      expect(klass).to eql TestEvent
    end

    describe "event name validation" do
      it "accepts string event IDs" do
        klass = nil
        expect do
          klass = @bus.register('TestEvent', TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql TestEvent
      end

      it "accepts symbolized/underscored event IDs" do
        klass = nil
        expect do
          klass = @bus.register(:test_event, TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql TestEvent

        expect do
          @bus.register(:inner_test_event, TestHandler.new)
        end.to raise_error(NameError)

        bus = ::Octiron::Events::Bus.new(::TestModule)
        expect do
          klass = bus.register(:inner_test_event, TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql TestModule::InnerTestEvent
      end

    end
  end

  describe "event notification" do
    before :each do
      @bus = ::Octiron::Events::Bus.new(::Octiron::Events)
    end

    it "notifies a single handler object" do
      event = TestEvent.new
      handler = TestHandler.new

      @bus.register(TestEvent, handler)
      @bus.notify(event)

      expect(handler.invoked).to be_truthy
      expect(handler.event.object_id).to eql event.object_id
    end

    it "notifies multiple handler objects" do
      event = TestEvent.new
      handler1 = TestHandler.new
      handler2 = TestHandler.new

      @bus.register(TestEvent, handler1)
      @bus.register(TestEvent, handler2)
      @bus.notify(event)

      expect(handler1.invoked).to be_truthy
      expect(handler1.event.object_id).to eql event.object_id
      expect(handler2.invoked).to be_truthy
      expect(handler2.event.object_id).to eql event.object_id
    end

    it "notifies a single handler proc" do
      event = TestEvent.new
      got_event = nil

      @bus.register(TestEvent) do |event|
        got_event = event
      end
      @bus.notify(event)

      expect(got_event.object_id).to eql event.object_id
    end

    it "notifies multiple handler procs" do
      event = TestEvent.new
      got_event1 = nil
      got_event2 = nil

      @bus.register(TestEvent) do |event|
        got_event1 = event
      end
      @bus.register(TestEvent) do |event|
        got_event2 = event
      end
      @bus.notify(event)

      expect(got_event1.object_id).to eql event.object_id
      expect(got_event2.object_id).to eql event.object_id
    end
  end
end
