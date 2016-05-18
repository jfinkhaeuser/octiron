# coding: utf-8
#
# octiron
# https://github.com/jfinkhaeuser/octiron
#
# Copyright (c) 2016 Jens Finkhaeuser and other octiron contributors.
# All rights reserved.
#

require 'rgl/adjacency'
require 'rgl/dijkstra'

require 'octiron/support/camel_case'
require 'octiron/support/constantize'

# require 'collapsium/recursive_sort'
# require 'collapsium/prototype_match'

module Octiron::Transmogrifiers

  ##
  # Registers transmogrifiers between one (event) class and another.
  #
  # A transmogrifier is an object with a call method or a block that accepts
  # an instance of one (event) class and produces an instance of another
  # (event) class.
  #
  # The registry also exposes a #transmogrify function which uses any
  # registered transmogrifier, or raises an error if there is no
  # transmogrification possible.
  #
  # One piece of magic makes this particularly powerful: the registry creates
  # a graph of how to transmogrify an object to another by chaining
  # transmogrifiers. That is, if there is a transmogrifier that turns A into B,
  # and one that turns B into C, then by chaining both the registry can also
  # turn A into C directly. (This is done via the 'rgl' gem).
  class Registry
    # @return (String) the default namespace to search for transmogrifiers
    attr_reader :default_namespace

    ##
    # @param default_namespace (Symbol) The default namespace to look in for
    #     Transmogrifier classes.
    def initialize(default_namespace = ::Octiron::Transmogrifiers)
      @default_namespace = default_namespace.to_s
      @graph = RGL::DirectedAdjacencyGraph.new
      @visitor = RGL::DijkstraVisitor.new(@graph)
      @map_data = {}
      @map = nil
      @transmogrifiers = {}
    end

    ##
    # Register transmogrifier
    #
    # @param from (Class, String, other) A class or String nameing a
    #     transmogrifier source. With prototype Hash matching, this would be
    #     a prototype.
    # @param to (Class, String, other) Transmogrifier target.
    # @param overwrite (Boolean) The registry can only hold one transmogrifier
    #     per from -> to pair. If overwrite is true, registering a
    #     transmogrifier where one already exists overwrites the old one,
    #     otherwise an exception is raised.
    # @param transmogrifier_object (Object) Transmogrifier object that must
    #     implement a `#call` method accepting an instance of the event class
    #     provided in the first parameter. If nil, a block needs to be provided.
    # @param transmogrifier_proc (Proc) Transmogrifier block that accepts an
    #     instance of the event class provided in the first parameter. If nil, a
    #     transmogrifier object must be provided.
    def register(from, to, overwrite = false, transmogrifier_object = nil,
                 &transmogrifier_proc)
      transmogrifier = transmogrifier_proc || transmogrifier_object
      if not transmogrifier
        raise ArgumentError, "Please pass either an object or a transmogrifier "\
            "block"
      end

      # Convert to canonical names
      from_name = parse_name(from)
      to_name = parse_name(to)
      key = [from_name, to_name]

      # We treat the graph as authoritative for what transmogrifiers exist.
      if @graph.has_edge?(from_name, to_name)
        if not overwrite
          raise ArgumentError, "Registry already knows a transmogrifier for "\
              "#{key}, aborting!"
        end
      end

      # Add edges and map data for the shortest path search. We treat all paths
      # as equally weighted.
      @graph.add_edge(from_name, to_name)
      @map_data[key] = 1
      @map = RGL::EdgePropertiesMap.new(@map_data, true)

      # Finally, register transmogrifier
      @transmogrifiers[key] = transmogrifier
    end

    ##
    # Deregister transmogrifier
    #
    # @param from (Class, String, other) A class or String nameing a
    #     transmogrifier source. With prototype Hash matching, this would be
    #     a prototype.
    # @param to (Class, String, other) Transmogrifier target.
    def deregister(from, to)
      # Convert to canonical names
      from_name = parse_name(from)
      to_name = parse_name(to)
      key = [from_name, to_name]

      # Graph, map data and transmogrifiers need to be modified
      @graph.remove_edge(from_name, to_name)
      @map_data.delete(key)
      @map = RGL::EdgePropertiesMap.new(@map_data, true)

      @transmogrifiers.delete(key)
    end

    alias unregister deregister

    ##
    # Transmogrify an object of one class into another class.
    def transmogrify(from, to)
      # Get lookup keys
      from_name = from.class.to_s
      to_name = parse_name(to)

      # We'll ask the graph for the shortest path. If there is none, we can't
      # transmogrify. (Note: the @map changes with each registration/
      # deregistration, so we instanciate the algorithm here).
      algo = RGL::DijkstraAlgorithm.new(@graph, @map, @visitor)
      path = algo.shortest_path(from_name, to_name)

      if path.nil?
        raise ArgumentError, "No transmogrifiers for #{[from_name, to_name]} "\
            "found, aborting!"
      end

      # Transmogrify for each part of the path
      input = from
      result = nil
      path.inject do |step_from, step_to|
        key = [step_from, step_to]
        result = @transmogrifiers[key].call(input)
        if result.class.to_s != step_to
          raise "Transmogrifier returned result of invalid class "\
              "#{result.class}, aborting!"
        end
        input = result

        # Make step_to the next step_from
        next step_to
      end
      return result
    end

    private

    include ::Octiron::Support::CamelCase
    include ::Octiron::Support::Constantize

    def parse_name(name)
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
  end # class Registry
end # module Octiron::Transmogrifiers
