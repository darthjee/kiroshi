# frozen_string_literal: true

module Kiroshi
  class Filters
    module ClassMethods
      # Defines a filter for the current filter class
      #
      # This method is used at the class level to configure filters that will
      # be applied when {#apply} is called. Each call creates a new {Filter}
      # instance with the specified configuration.
      #
      # @overload filter_by(attribute, **options)
      #   @param attribute [Symbol] the attribute name to filter by
      #   @param options [Hash] additional options passed to {Filter#initialize}
      #   @option options [Symbol] :match (:exact) the matching type
      #     - +:exact+ for exact matching (default)
      #     - +:like+ for partial matching using SQL LIKE
      #   @option options [String, Symbol, nil] :table (nil) the table name to qualify the attribute
      #
      # @return [Filter] the new filter instance
      #
      # @example Defining exact match filters
      #   class ProductFilters < Kiroshi::Filters
      #     filter_by :category
      #     filter_by :brand
      #   end
      #
      # @example Defining partial match filters
      #   class SearchFilters < Kiroshi::Filters
      #     filter_by :title, match: :like
      #     filter_by :description, match: :like
      #   end
      #
      # @example Mixed filter types
      #   class OrderFilters < Kiroshi::Filters
      #     filter_by :customer_name, match: :like
      #     filter_by :status, match: :exact
      #     filter_by :payment_method
      #   end
      #
      # @example Filter with table qualification
      #   class DocumentTagFilters < Kiroshi::Filters
      #     filter_by :name, table: :tags
      #   end
      #
      # @since 0.1.0
      def filter_by(attribute, **)
        Filter.new(attribute, **).tap do |filter|
          filter_configs[attribute] = filter
        end
      end

      # @ api private
      # Returns the hash of configured filters for this class
      #
      # @return [Hash<Symbol, Filter>] hash of {Filter} instances configured
      #   for this filter class, keyed by attribute name
      #
      # @example Accessing configured filters
      #   class MyFilters < Kiroshi::Filters
      #     filter_by :name
      #     filter_by :status, match: :like
      #   end
      #
      #   MyFilters.filter_configs.length # => 2
      #   MyFilters.filter_configs[:name].attribute # => :name
      #   MyFilters.filter_configs[:status].match # => :like
      #
      # @since 0.1.2
      def filter_configs
        @filter_configs ||= {}
      end
    end
  end
end
