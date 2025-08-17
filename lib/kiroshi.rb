# frozen_string_literal: true

# @api public
# @author darthjee
module Kiroshi
  autoload :VERSION,      'kiroshi/version'

  autoload :Filters,      'kiroshi/filters'
  autoload :Filter,       'kiroshi/filter'
  autoload :FilterRunner, 'kiroshi/filter_runner'
  autoload :FilterQuery,  'kiroshi/filter_query'
end
