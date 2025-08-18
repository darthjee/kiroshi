# frozen_string_literal: true

module Kiroshi
  # @author darthjee
  #
  # Factory class for creating filter query strategies
  #
  # This class implements the Strategy pattern for handling different types of
  # database queries based on the filter match type. It provides a factory method
  # to create the appropriate query strategy class.
  #
  # @example Getting an exact match query strategy
  #   query = Kiroshi::FilterQuery.for(:exact).new(filter_runner)
  #   query.apply
  #
  # @example Getting a LIKE match query strategy
  #   query = Kiroshi::FilterQuery.for(:like).new(filter_runner)
  #   query.apply
  #
  # @since 0.1.1
  class FilterQuery
    class << self
      # Factory method to create the appropriate query strategy
      #
      # This method returns the correct query strategy class based on the
      # match type provided. It serves as the main entry point for creating
      # query strategies.
      #
      # @param match [Symbol] the type of matching to perform
      #   - :exact for exact matching
      #   - :like for partial matching using SQL LIKE
      #
      # @return [Class] the appropriate FilterQuery subclass
      #
      # @example Creating an exact match query
      #   query_class = Kiroshi::FilterQuery.for(:exact)
      #   # Returns Kiroshi::FilterQuery::Exact
      #
      # @example Creating a LIKE match query
      #   query_class = Kiroshi::FilterQuery.for(:like)
      #   # Returns Kiroshi::FilterQuery::Like
      #
      # @raise [ArgumentError] when an unsupported match type is provided
      #
      # @since 0.1.1
      def for(match)
        case match
        when :exact
          Exact
        when :like
          Like
        else
          raise ArgumentError, "Unsupported match type: #{match}"
        end
      end
    end

    # Creates a new FilterQuery instance
    #
    # @param filter_runner [Kiroshi::FilterRunner] the filter runner instance
    #
    # @since 0.1.1
    def initialize(filter_runner)
      @filter_runner = filter_runner
    end

    # Base implementation for applying a filter query
    #
    # This method should be overridden by subclasses to provide specific
    # query logic for each match type.
    #
    # @return [ActiveRecord::Relation] the filtered scope
    #
    # @raise [NotImplementedError] when called on the base class
    #
    # @since 0.1.1
    def apply
      raise NotImplementedError, 'Subclasses must implement #apply method'
    end

    private

    attr_reader :filter_runner

    # @!method filter_runner
    #   @api private
    #   @private
    #
    #   Returns the filter runner instance
    #
    #   @return [Kiroshi::FilterRunner] the filter runner instance

    delegate :scope, :attribute, :table_name, :filter_value, to: :filter_runner

    # @!method scope
    #   @api private
    #   @private
    #
    #   Returns the ActiveRecord scope being filtered
    #
    #   @return [ActiveRecord::Relation] the scope being filtered

    # @!method attribute
    #   @api private
    #   @private
    #
    #   Returns the attribute name to filter by
    #
    #   @return [Symbol] the attribute name to filter by

    # @!method table_name
    #   @api private
    #   @private
    #
    #   Returns the table name from the scope
    #
    #   @return [String] the table name

    # @!method filter_value
    #   @api private
    #   @private
    #
    #   Returns the filter value for the current filter's attribute
    #
    #   @return [Object, nil] the filter value or nil if not present

    # @author darthjee
    #
    # Query strategy for exact matching
    #
    # This class implements the exact match query strategy, generating
    # WHERE clauses with exact equality comparisons.
    #
    # @example Applying exact match query
    #   query = Kiroshi::FilterQuery::Exact.new(filter_runner)
    #   query.apply
    #   # Generates: WHERE attribute = 'value'
    #
    # @since 0.1.1
    class Exact < FilterQuery
      # Applies exact match filtering to the scope
      #
      # This method generates a WHERE clause with exact equality matching
      # for the filter's attribute and value.
      #
      # @return [ActiveRecord::Relation] the filtered scope with exact match
      #
      # @example Applying exact match
      #   query = Exact.new(filter_runner)
      #   query.apply
      #   # Generates: WHERE status = 'published'
      #
      # @since 0.1.1
      def apply
        scope.where(attribute => filter_value)
      end
    end

    # @author darthjee
    #
    # Query strategy for LIKE matching
    #
    # This class implements the LIKE match query strategy, generating
    # WHERE clauses with SQL LIKE operations for partial matching.
    #
    # @example Applying LIKE match query
    #   query = Kiroshi::FilterQuery::Like.new(filter_runner)
    #   query.apply
    #   # Generates: WHERE table_name.attribute LIKE '%value%'
    #
    # @since 0.1.1
    class Like < FilterQuery
      # Applies LIKE match filtering to the scope
      #
      # This method generates a WHERE clause with SQL LIKE operation
      # for partial matching, including table name prefix to avoid
      # column ambiguity in complex queries.
      #
      # @return [ActiveRecord::Relation] the filtered scope with LIKE match
      #
      # @example Applying LIKE match
      #   query = Like.new(filter_runner)
      #   query.apply
      #   # Generates: WHERE documents.name LIKE '%ruby%'
      #
      # @since 0.1.1
      def apply
        scope.where(
          "#{table_name}.#{attribute} LIKE ?",
          "%#{filter_value}%"
        )
      end
    end
  end
end
