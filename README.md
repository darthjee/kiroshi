# Kiroshi
[![Build Status](https://circleci.com/gh/darthjee/kiroshi.svg?style=shield)](https://circleci.com/gh/darthjee/kiroshi)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/35480a5e82e74ff7a0186697b3f61a4b)](https://app.codacy.com/gh/darthjee/kiroshi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

![kiroshi](https://raw.githubusercontent.com/darthjee/kiroshi/master/kiroshi.jpg)


## Yard Documentation

[https://www.rubydoc.info/gems/kiroshi/0.1.0](https://www.rubydoc.info/gems/kiroshi/0.1.0)

Kiroshi has been designed to make filtering ActiveRecord queries easier
by providing a flexible and reusable filtering system. It allows you to
define filter sets that can be applied to any ActiveRecord scope,
supporting both exact matches and partial matching using SQL LIKE operations.

Current Release: [0.1.0](https://github.com/darthjee/kiroshi/tree/0.1.0)

[Next release](https://github.com/darthjee/kiroshi/compare/0.1.0...master)

## Installation

- Install it

```ruby
  gem install kiroshi
```

- Or add Kiroshi to your `Gemfile` and `bundle install`:

```ruby
  gem 'kiroshi'
```

```bash
  bundle install kiroshi
```

## Usage

### Kiroshi::Filters

[Filters](https://www.rubydoc.info/gems/kiroshi/Kiroshi/Filters)
is a base class for implementing filter sets on ActiveRecord scopes.
It uses a class-level DSL to define filters and an instance-level interface to apply them.

#### Basic Usage

```ruby
# Define a filter class
class DocumentFilters < Kiroshi::Filters
  filter_by :name, match: :like
  filter_by :status
  filter_by :category
end

# Apply filters to a scope
filters = DocumentFilters.new(name: 'report', status: 'published')
filtered_documents = filters.apply(Document.all)
# Generates: WHERE name LIKE '%report%' AND status = 'published'
```

#### Filter Types

Kiroshi supports two types of matching:

- `:exact` - Exact match (default)
- `:like` - Partial match using SQL LIKE

```ruby
class UserFilters < Kiroshi::Filters
  filter_by :email, match: :like      # Partial matching
  filter_by :role                     # Exact matching (default)
  filter_by :active, match: :exact    # Explicit exact matching
end

filters = UserFilters.new(email: 'admin', role: 'moderator')
filtered_users = filters.apply(User.all)
# Generates: WHERE email LIKE '%admin%' AND role = 'moderator'
```

#### Advanced Examples

##### Multiple Filter Types

```ruby
class ProductFilters < Kiroshi::Filters
  filter_by :name, match: :like
  filter_by :category
  filter_by :price, match: :exact
  filter_by :brand
end

# Apply only some filters
filters = ProductFilters.new(name: 'laptop', category: 'electronics')
products = filters.apply(Product.all)
# Only name and category filters are applied, price and brand are ignored
```

##### Controller Integration

```ruby
class DocumentsController < ApplicationController
  def index
    @documents = document_filters.apply(Document.all)
    render json: @documents
  end

  private

  def document_filters
    DocumentFilters.new(filter_params)
  end

  def filter_params
    params.permit(:name, :status, :category, :author)
  end
end

class DocumentFilters < Kiroshi::Filters
  filter_by :name, match: :like
  filter_by :status
  filter_by :category
  filter_by :author, match: :like
end
```

##### Nested Resource Filtering

```ruby
class ArticleFilters < Kiroshi::Filters
  filter_by :title, match: :like
  filter_by :published
  filter_by :tag, match: :like
end

# In your controller
def articles
  base_scope = current_user.articles
  article_filters.apply(base_scope)
end

def article_filters
  ArticleFilters.new(params.permit(:title, :published, :tag))
end
```

### Kiroshi::Filter

[Filter](https://www.rubydoc.info/gems/kiroshi/Kiroshi/Filter)
is the individual filter class that applies filtering logic to ActiveRecord scopes.
It's automatically used by `Kiroshi::Filters`, but can also be used standalone.

#### Standalone Usage

```ruby
# Create individual filters
name_filter = Kiroshi::Filter.new(:name, match: :like)
status_filter = Kiroshi::Filter.new(:status, match: :exact)

# Apply filters manually
scope = Document.all
scope = name_filter.apply(scope, { name: 'report' })
scope = status_filter.apply(scope, { status: 'published' })
```

#### Filter Options

- `match: :exact` - Performs exact matching (default)
- `match: :like` - Performs partial matching using SQL LIKE

```ruby
# Exact match filter
exact_filter = Kiroshi::Filter.new(:status)
exact_filter.apply(Document.all, { status: 'published' })
# Generates: WHERE status = 'published'

# LIKE match filter
like_filter = Kiroshi::Filter.new(:title, match: :like)
like_filter.apply(Document.all, { title: 'Ruby' })
# Generates: WHERE title LIKE '%Ruby%'
```

#### Empty Value Handling

Filters automatically ignore empty or nil values:

```ruby
filter = Kiroshi::Filter.new(:name)
filter.apply(Document.all, { name: nil })        # Returns original scope
filter.apply(Document.all, { name: '' })         # Returns original scope  
filter.apply(Document.all, {})                   # Returns original scope
filter.apply(Document.all, { name: 'value' })    # Applies filter
```
