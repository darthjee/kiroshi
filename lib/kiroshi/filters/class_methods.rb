# frozen_string_literal: true

module Kiroshi
  class Filters
    # @api public
    # Class-level methods for configuring filters in Kiroshi::Filters
    #
    # This module provides the DSL methods that allow filter classes to
    # define their filtering behavior using class-level method calls.
    # These methods are automatically available when extending Kiroshi::Filters.
    #
    # The primary interface is the {.filter_by} method, which registers
    # filters that will be applied when {Filters#apply} is called on
    # instances of the filter class.
    #
    # @example Basic filter configuration
    #   class DocumentFilters < Kiroshi::Filters
    #     filter_by :name, match: :like
    #     filter_by :status
    #     filter_by :category, table: :documents
    #   end
    #
    # @example Accessing filter configurations
    #   DocumentFilters.filter_configs.keys # => [:name, :status, :category]
    #   DocumentFilters.filter_configs[:name].match # => :like
    #
    # @since 0.1.2
    # @author darthjee
    module ClassMethods
      # Defines a filter for the current filter class
      #
      # This method is used at the class level to configure filters that will
      # be applied when {Filters#apply} is called. Each call creates a new {Filter}
      # instance with the specified configuration and stores it in the class's
      # filter registry for later use during filtering operations.
      #
      # The method supports various matching strategies and table qualification
      # options to handle complex database queries with joins and ambiguous
      # column names.
      #
      # @overload filter_by(attribute, **options)
      #   @param attribute [Symbol] the attribute name to filter by
      #   @param options [Hash] additional options passed to {Filter#initialize}
      #   @option options [Symbol] :match (:exact) the matching type
      #     - +:exact+ for exact matching (default)
      #     - +:like+ for partial matching using SQL LIKE with wildcards
      #   @option options [String, Symbol, nil] :table (nil) the table name to qualify the attribute
      #     when dealing with joined tables that have conflicting column names
      #
      # @return [Filter] the new filter instance that was created and registered
      #
      # @example Defining exact match filters
      #   class ProductFilters < Kiroshi::Filters
      #     filter_by :category      # Exact match on category
      #     filter_by :brand         # Exact match on brand
      #     filter_by :active        # Exact match on active status
      #   end
      #
      # @example Defining partial match filters
      #   class SearchFilters < Kiroshi::Filters
      #     filter_by :title, match: :like         # Partial match on title
      #     filter_by :description, match: :like   # Partial match on description
      #     filter_by :author_name, match: :like   # Partial match on author name
      #   end
      #
      # @example Mixed filter types with different matching strategies
      #   class OrderFilters < Kiroshi::Filters
      #     filter_by :customer_name, match: :like  # Partial match for customer search
      #     filter_by :status, match: :exact        # Exact match for order status
      #     filter_by :payment_method               # Exact match (default) for payment
      #   end
      #
      # @example Filters with table qualification for joined queries
      #   class DocumentTagFilters < Kiroshi::Filters
      #     filter_by :name, table: :documents      # Filter by document name
      #     filter_by :tag_name, table: :tags       # Filter by tag name
      #     filter_by :category, table: :categories # Filter by category name
      #   end
      #
      # @example Complex real-world filter class
      #   class ProductSearchFilters < Kiroshi::Filters
      #     filter_by :name, match: :like                    # Product name search
      #     filter_by :category_id                           # Exact category match
      #     filter_by :brand, match: :like                   # Brand name search
      #     filter_by :price_min                             # Minimum price
      #     filter_by :price_max                             # Maximum price
      #     filter_by :in_stock                              # Availability filter
      #     filter_by :category_name, table: :categories     # Category name via join
      #   end
      #
      # @note When using table qualification, ensure that the specified table
      #   is properly joined in the scope being filtered. The filter will not
      #   automatically add joins - it only qualifies the column name.
      #
      # @see Filter#initialize for detailed information about filter options
      # @see Filters#apply for how these filters are used during query execution
      #
      # @since 0.1.0
      def filter_by(attribute, **)
        Filter.new(attribute, **).tap do |filter|
          filter_configs[attribute] = filter
        end
      end

      # @api private
      # Returns the hash of configured filters for this filter class
      #
      # This method provides access to the internal registry of filters
      # that have been configured using {.filter_by}. The returned hash
      # contains {Filter} instances keyed by their attribute names, allowing
      # for efficient O(1) lookup during filter application.
      #
      # This method is primarily used internally by {Filters#apply} to
      # iterate through and apply all configured filters to a scope.
      # While marked as private API, it may be useful for introspection
      # and testing purposes.
      #
      # @return [Hash<Symbol, Filter>] hash of {Filter} instances configured
      #   for this filter class, keyed by attribute name for efficient access
      #
      # @example Accessing configured filters for introspection
      #   class MyFilters < Kiroshi::Filters
      #     filter_by :name, match: :like
      #     filter_by :status
      #     filter_by :category, table: :categories
      #   end
      #
      #   MyFilters.filter_configs.length                    # => 3
      #   MyFilters.filter_configs.keys                      # => [:name, :status, :category]
      #   MyFilters.filter_configs[:name].attribute          # => :name
      #   MyFilters.filter_configs[:name].match              # => :like
      #   MyFilters.filter_configs[:status].match            # => :exact
      #   MyFilters.filter_configs[:category].table_name     # => :categories
      #
      # @example Using in tests to verify filter configuration
      #   RSpec.describe ProductFilters do
      #     it 'configures the expected filters' do
      #       expect(described_class.filter_configs).to have_key(:name)
      #       expect(described_class.filter_configs[:name].match).to eq(:like)
      #     end
      #   end
      #
      # @note This method returns a reference to the actual internal hash.
      #   Modifying the returned hash directly will affect the filter class
      #   configuration. Use {.filter_by} for proper filter registration.
      #
      # @note The hash is lazily initialized on first access and persists
      #   for the lifetime of the class. Each filter class maintains its
      #   own separate filter_configs hash.
      #
      # @see .filter_by for adding filters to this configuration
      # @see Filters#apply for how these configurations are used
      #
      # @since 0.1.2
      def filter_configs
        @filter_configs ||= {}
      end
    end
  end
end
