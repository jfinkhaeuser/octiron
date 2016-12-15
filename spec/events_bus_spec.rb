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
    @invoked = 0
    @event = nil
  end

  def call(event)
    @event = event
    @invoked += 1
  end
end

describe Octiron::Events::Bus do
  describe "construction" do
    it "can be constructed without a default namespace" do
      bus = nil
      expect do
        bus = ::Octiron::Events::Bus.new
      end.not_to raise_error

      expect(bus.default_namespace).to eql 'Octiron::Events'
    end

    it "can be constructed with a namespace" do
      bus = nil
      expect do
        bus = ::Octiron::Events::Bus.new(::Octiron::Events)
      end.not_to raise_error

      expect(bus.default_namespace).to eql 'Octiron::Events'
    end
  end

  describe "subscription" do
    before :each do
      @bus = ::Octiron::Events::Bus.new(::Octiron::Events)
    end

    it "requires a handler" do
      expect do
        @bus.subscribe(TestEvent)
      end.to raise_error(ArgumentError)
    end

    it "can subscribe an object handler for an event" do
      klass = nil
      expect do
        klass = @bus.subscribe(TestEvent, TestHandler.new)
      end.not_to raise_error
      expect(klass).to eql 'TestEvent'
    end

    it "can subscribe a handler proc for an event" do
      klass = nil
      expect do
        klass = @bus.subscribe(TestEvent) do |_|
        end
      end.not_to raise_error
      expect(klass).to eql 'TestEvent'
    end

    describe "event name validation" do
      it "accepts string event IDs" do
        klass = nil
        expect do
          klass = @bus.subscribe('TestEvent', TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql 'TestEvent'
      end

      it "accepts symbolized/underscored event IDs" do
        klass = nil
        expect do
          klass = @bus.subscribe(:test_event, TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql 'TestEvent'

        expect do
          @bus.subscribe(:inner_test_event, TestHandler.new)
        end.to raise_error(NameError)

        bus = ::Octiron::Events::Bus.new(::TestModule)
        expect do
          klass = bus.subscribe(:inner_test_event, TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql 'TestModule::InnerTestEvent'
      end

      it "accepts Hash event IDs" do
        proto = {
          a: nil,
          b: {
            c: 42,
          },
        }

        klass = nil
        expect do
          klass = @bus.subscribe(proto, TestHandler.new)
        end.not_to raise_error
        expect(klass).to eql proto
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

      @bus.subscribe(TestEvent, handler)
      @bus.publish(event)

      expect(handler.invoked).to eql 1
      expect(handler.event.object_id).to eql event.object_id
    end

    it "notifies multiple handler objects" do
      event = TestEvent.new
      handler1 = TestHandler.new
      handler2 = TestHandler.new

      @bus.subscribe(TestEvent, handler1)
      @bus.subscribe(TestEvent, handler2)
      @bus.publish(event)

      expect(handler1.invoked).to eql 1
      expect(handler1.event.object_id).to eql event.object_id
      expect(handler2.invoked).to eql 1
      expect(handler2.event.object_id).to eql event.object_id
    end

    it "notifies a single handler proc" do
      event = TestEvent.new
      got_event = nil

      @bus.subscribe(TestEvent) do |fired|
        got_event = fired
      end
      @bus.publish(event)

      expect(got_event.object_id).to eql event.object_id
    end

    it "notifies multiple handler procs" do
      event = TestEvent.new
      got_event1 = nil
      got_event2 = nil

      @bus.subscribe(TestEvent) do |fired|
        got_event1 = fired
      end
      @bus.subscribe(TestEvent) do |fired|
        got_event2 = fired
      end
      @bus.publish(event)

      expect(got_event1.object_id).to eql event.object_id
      expect(got_event2.object_id).to eql event.object_id
    end

    it "notifies from a Hash event" do
      proto = {
        a: nil,
        b: {
          c: 42,
        },
      }
      handler = TestHandler.new

      @bus.subscribe(proto, handler)

      # Bad event #1
      bad_event1 = {
        a: 'foo',
        # :b is missing
      }
      @bus.publish(bad_event1)
      expect(handler.invoked).to eql 0

      # Bad event #2
      bad_event2 = {
        a: 'foo',
        b: {
          c: 123, # value mismatch
        }
      }
      @bus.publish(bad_event2)
      expect(handler.invoked).to eql 0

      # Good event
      good_event = {
        a: 'foo',
        b: {
          c: 42,
        }
      }
      @bus.publish(good_event)
      expect(handler.invoked).to eql 1
    end

    it "matches multiple Hash prototypes" do
      # Two similar prototypes
      proto1 = {
        a: 42,
      }
      handler1 = TestHandler.new
      @bus.subscribe(proto1, handler1)

      proto2 = {
        a: nil,
      }
      handler2 = TestHandler.new
      @bus.subscribe(proto2, handler2)

      # Fire one event that matches both
      @bus.publish(a: 42)

      expect(handler1.invoked).to eql 1
      expect(handler2.invoked).to eql 1
    end

    it "stores handlers for the best matching prototype" do
      # Two different prototypes
      proto1 = {
        b: 42,
      }
      handler1 = TestHandler.new
      @bus.subscribe(proto1, handler1)

      proto2 = {
        a: nil,
      }
      handler2 = TestHandler.new
      @bus.subscribe(proto2, handler2)

      handler3 = TestHandler.new
      @bus.subscribe(proto2, handler3)

      # Fire one event that matches one prototype
      @bus.publish(a: 42)

      expect(handler1.invoked).to eql 0
      expect(handler2.invoked).to eql 1
      expect(handler3.invoked).to eql 1
    end
  end

  describe "unsubscription" do
    before :each do
      @bus = ::Octiron::Events::Bus.new(::Octiron::Events)
    end

    it "requires a handler" do
      expect do
        @bus.unsubscribe(TestEvent)
      end.to raise_error(ArgumentError)
    end

    it "unsubscripes object handlers properly" do
      event = TestEvent.new
      handler1 = TestHandler.new
      handler2 = TestHandler.new

      @bus.subscribe(TestEvent, handler1)
      @bus.subscribe(TestEvent, handler2)
      @bus.publish(event)

      expect(handler1.invoked).to eql 1
      expect(handler1.event.object_id).to eql event.object_id
      expect(handler2.invoked).to eql 1
      expect(handler2.event.object_id).to eql event.object_id

      @bus.unsubscribe(TestEvent, handler2)
      @bus.publish(event)

      expect(handler1.invoked).to eql 2
      expect(handler2.invoked).to eql 1
    end

    it "unsubscripes proc handlers properly" do
      event = TestEvent.new
      invoked1 = 0
      invoked2 = 0

      @bus.subscribe(TestEvent) do |_|
        invoked1 += 1
      end
      second = proc do |_|
        invoked2 += 1
      end
      @bus.subscribe(TestEvent, &second)
      @bus.publish(event)

      expect(invoked1).to eql 1
      expect(invoked2).to eql 1

      @bus.unsubscribe(TestEvent, &second)
      @bus.publish(event)

      expect(invoked1).to eql 2
      expect(invoked2).to eql 1
    end
  end

  context "event handler classes" do
    before :each do
      @bus = ::Octiron::Events::Bus.new(::Octiron::Events)
    end

    it "executes handlers in order of handler classes" do
      invoked = []
      @bus.subscribe(TestEvent, nil, 1) do |_|
        invoked << 1
      end
      @bus.subscribe(TestEvent, nil, 2) do |_|
        invoked << 2
      end
      @bus.subscribe(TestEvent, nil, 0) do |_|
        invoked << 0
      end

      @bus.publish(TestEvent.new)

      # Since we used a simple numeric class for each handler, we expect the
      # handlers to be executed in numeric sort order - independent of the order
      # they were subscribed.
      expect(invoked).to eql [0, 1, 2]
    end
  end
end
