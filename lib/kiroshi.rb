# frozen_string_literal: true

# @api public
# @author darthjee
#
# Kiroshi - Flexible ActiveRecord Query Filtering
#
# Kiroshi provides a clean and extensible way to filter ActiveRecord queries
# using a declarative DSL. It supports multiple matching strategies and can
# be easily integrated into Rails controllers and other components.
#
# The gem is designed around the main concept:
# - {Filters}: A base class for creating reusable filter sets
#
# Individual filters are handled internally and don't require direct interaction.
#
# @example Basic filter class definition
#   class DocumentFilters < Kiroshi::Filters
#     filter_by :name, match: :like
#     filter_by :status
#     filter_by :category
#   end
#
#   # Usage
#   filters = DocumentFilters.new(name: 'report', status: 'published')
#   filtered_documents = filters.apply(Document.all)
#   # Generates: WHERE name LIKE '%report%' AND status = 'published'
#
# @example Controller integration
#   # URL: /articles?filter[title]=ruby&filter[author]=john&filter[category]=tech
#   class ArticlesController < ApplicationController
#     def index
#       @articles = article_filters.apply(Article.published)
#       render json: @articles
#     end
#
#     private
#
#     def article_filters
#       ArticleFilters.new(filter_params)
#     end
#
#     def filter_params
#       params[:filter]&.permit(:title, :author, :category, :tag)
#     end
#   end
#
#   class ArticleFilters < Kiroshi::Filters
#     filter_by :title, match: :like
#     filter_by :author, match: :like
#     filter_by :category
#     filter_by :tag
#   end
#
# @example Advanced filtering scenarios
#   class UserFilters < Kiroshi::Filters
#     filter_by :email, match: :like
#     filter_by :role
#     filter_by :active, match: :exact
#     filter_by :department
#   end
#
#   # Apply multiple filters
#   filters = UserFilters.new(
#     email: 'admin',
#     role: 'moderator',
#     active: true
#   )
#   filtered_users = filters.apply(User.includes(:department))
#   # Generates: WHERE email LIKE '%admin%' AND role = 'moderator' AND active = true
#
# @example Empty value handling
#   filters = DocumentFilters.new(name: '', status: 'published')
#   result = filters.apply(Document.all)
#   # Only status filter is applied, name is ignored due to empty value
#
# @example Chaining with existing scopes
#   # URL: /orders?filter[status]=completed&filter[customer_name]=john
#   class OrderFilters < Kiroshi::Filters
#     filter_by :customer_name, match: :like
#     filter_by :status
#     filter_by :payment_method
#   end
#
#   # Apply to pre-filtered scope
#   recent_orders = Order.where('created_at > ?', 1.month.ago)
#   filters = OrderFilters.new(status: 'completed', customer_name: 'john')
#   filtered_orders = filters.apply(recent_orders)
#
# @example Complex controller with pagination
#   # URL: /products?filter[name]=laptop&filter[category]=electronics&filter[in_stock]=true&page=2
#   class ProductsController < ApplicationController
#     def index
#       @products = filtered_products.page(params[:page])
#       render json: {
#         products: @products,
#         total: filtered_products.count,
#         filters_applied: applied_filter_count
#       }
#     end
#
#     private
#
#     def filtered_products
#       @filtered_products ||= product_filters.apply(base_scope)
#     end
#
#     def base_scope
#       Product.includes(:category, :brand).available
#     end
#
#     def product_filters
#       ProductFilters.new(filter_params)
#     end
#
#     def filter_params
#       params[:filter]&.permit(:name, :category, :brand, :price_range, :in_stock)
#     end
#
#     def applied_filter_count
#       filter_params.compact.count
#     end
#   end
#
#   class ProductFilters < Kiroshi::Filters
#     filter_by :name, match: :like
#     filter_by :category
#     filter_by :brand
#     filter_by :in_stock, match: :exact
#   end
#
# @see Filters Base class for creating filter sets
# @see https://github.com/darthjee/kiroshi GitHub repository
# @see https://www.rubydoc.info/gems/kiroshi YARD documentation
#
# @since 0.1.0
module Kiroshi
  autoload :VERSION,      'kiroshi/version'

  autoload :Filters,      'kiroshi/filters'
  autoload :Filter,       'kiroshi/filter'
  autoload :FilterRunner, 'kiroshi/filter_runner'
  autoload :FilterQuery,  'kiroshi/filter_query'
end
