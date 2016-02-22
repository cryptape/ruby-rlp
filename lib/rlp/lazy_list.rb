# -*- encoding : ascii-8bit -*-

module RLP
##
  # A RLP encoded list which decodes itself when necessary.
  #
  # Both indexing with positive indices and iterating are supported. Getting
  # the length is possible as well but requires full horizontal encoding.
  #
  class LazyList
    include Enumerable
    include DecodeLazy

    attr_accessor :sedes, :sedes_options

    ##
    # @param rlp [String] the rlp string in which the list is encoded
    # @param start [Integer] the position of the first payload byte of the
    #   encoded list
    # @param next_start [Integer] the position of the last payload byte of the
    #   encoded list
    # @param sedes [Object] a sedes object which deserializes each element of the
    #   list, or `nil` for on deserialization
    # @param sedes_options [Hash] keyword arguments which will be passed on to
    #   the deserializer
    #
    def initialize(rlp, start, next_start, sedes: nil, sedes_options: nil)
      @rlp = rlp
      @start = start
      @next_start = next_start
      @index = start
      @elements = []
      @size = nil
      @sedes = sedes
      @sedes_options = sedes_options
    end

    def next_item
      if @index == @next_start
        @size = @elements.size
        raise StopIteration
      elsif @index < @next_start
        item, @index = consume_item_lazy @rlp, @index

        if @sedes
          # FIXME: lazy man's kwargs
          item = @sedes_options.empty? ?
                   @sedes.deserialize(item) :
                   @sedes.deserialize(item, **@sedes_options)
        end

        @elements.push item
        item
      else
        raise "Assertion failed: index cannot be larger than next start"
      end
    end

    def each(&block)
      @elements.each(&block)
      loop { block.call(next_item) }
    end

    def [](i)
      fetch(i, nil)
    end

    def fetch(*args)
      i = args[0]

      loop do
        raise StopIteration if @elements.size > i
        next_item
      end

      @elements.fetch(*args)
    end

    def size
      unless @size
        loop { next_item }
      end
      @size
    end
    alias :length :size

  end
end
