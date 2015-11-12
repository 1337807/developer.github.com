module Nanoc::Int
  # Calculates rule memories for objects that can be run through a rule (item
  # representations and layouts).
  #
  # @api private
  class RuleMemoryCalculator
    extend Nanoc::Int::Memoization

    # @option params [Nanoc::Int::RulesCollection] rules_collection The rules
    #   collection
    def initialize(params = {})
      @rules_collection = params.fetch(:rules_collection) do
        raise ArgumentError, 'Required :rules_collection option is missing'
      end
    end

    # @param [#reference] obj The object to calculate the rule memory for
    #
    # @return [Array] The caluclated rule memory for the given object
    def [](obj)
      result =
        case obj
        when Nanoc::Int::ItemRep
          @rules_collection.new_rule_memory_for_rep(obj)
        when Nanoc::Int::Layout
          @rules_collection.new_rule_memory_for_layout(obj)
        else
          raise "Do not know how to calculate the rule memory for #{obj.inspect}"
        end

      result
    end
    memoize :[]
  end
end
