module Nanoc
  class ItemRepCollectionView
    include Enumerable

    class NoSuchItemRepError < ::Nanoc::Error
      def initialize(rep_name)
        super("No rep named #{rep_name.inspect} was found.")
      end
    end

    # @api private
    def initialize(item_reps)
      @item_reps = item_reps
    end

    # @api private
    def unwrap
      @item_reps
    end

    def to_ary
      @item_reps.map { |ir| Nanoc::ItemRepView.new(ir) }
    end

    # Calls the given block once for each item rep, passing that item rep as a parameter.
    #
    # @yieldparam [Nanoc::ItemRepView] item rep
    #
    # @yieldreturn [void]
    #
    # @return [self]
    def each
      @item_reps.each { |ir| yield Nanoc::ItemRepView.new(ir) }
      self
    end

    # @return [Integer]
    def size
      @item_reps.size
    end

    # Return the item rep with the given name, or nil if no item rep exists.
    #
    # @param [Symbol] rep_name
    #
    # @return [nil] if no item rep with the given name was found
    #
    # @return [Nanoc::ItemRepView] if an item rep with the given name was found
    def [](rep_name)
      res = @item_reps.find { |ir| ir.name == rep_name }
      res && Nanoc::ItemRepView.new(res)
    end

    # Return the item rep with the given name, or raises an exception if there
    # is no rep with the given name.
    #
    # @param [Symbol] rep_name
    #
    # @return [Nanoc::ItemRepView]
    #
    # @raise if no rep was found
    def fetch(rep_name)
      res = @item_reps.find { |ir| ir.name == rep_name }
      if res
        Nanoc::ItemRepView.new(res)
      else
        raise NoSuchItemRepError.new(rep_name)
      end
    end
  end
end
