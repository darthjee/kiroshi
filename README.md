# Kiroshi
[![Build Status](https://circleci.com/gh/darthjee/kiroshi.svg?style=shield)](https://circleci.com/gh/darthjee/kiroshi)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/35480a5e82e74ff7a0186697b3f61a4b)](https://app.codacy.com/gh/darthjee/kiroshi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

![kiroshi](https://raw.githubusercontent.com/darthjee/kiroshi/master/kiroshi.jpg)


## Yard Documentation

[https://www.rubydoc.info/gems/kiroshi/0.1.1](https://www.rubydoc.info/gems/kiroshi/0.1.1)

Kiroshi has been designed to make filtering ActiveRecord queries easier
by providing a flexible and reusable filtering system. It allows you to
define filter sets that can be applied to any ActiveRecord scope,
supporting both exact matches and partial matching using SQL LIKE operations.

Current Release: [0.1.1](https://github.com/darthjee/kiroshi/tree/0.1.1)

[Next release](https://github.com/darthjee/kiroshi/compare/0.1.1...master)

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
# URL: /documents?filter[name]=report&filter[status]=published&filter[author]=john
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
    params[:filter]&.permit(:name, :status, :category, :author)
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
# URL: /users/123/articles?filter[title]=ruby&filter[published]=true&filter[tag]=tutorial
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
  ArticleFilters.new(params[:filter]&.permit(:title, :published, :tag))
end
```

##### Joined Tables and Table Qualification

When working with joined tables that have columns with the same name, you can specify which table to filter on using the `table` parameter:

```ruby
class DocumentFilters < Kiroshi::Filters
  filter_by :name, match: :like                    # Filters by documents.name (default table)
  filter_by :tag_name, match: :like, table: :tags  # Filters by tags.name
  filter_by :status                                # Filters by documents.status
  filter_by :category, table: :documents           # Explicitly filter by documents.category
end

# Example with joined scope
scope = Document.joins(:tags)
filters = DocumentFilters.new(tag_name: 'ruby', status: 'published')
filtered_documents = filters.apply(scope)
# Generates: WHERE tags.name LIKE '%ruby%' AND documents.status = 'published'
```

###### Table Qualification Examples

```ruby
# Filter documents by tag name and document status
class DocumentTagFilters < Kiroshi::Filters
  filter_by :tag_name, match: :like, table: :tags  # Search in tags.name
  filter_by :status, table: :documents             # Search in documents.status
  filter_by :title, match: :like                   # Search in documents.title (default table)
end

scope = Document.joins(:tags)
filters = DocumentTagFilters.new(tag_name: 'programming', status: 'published', title: 'Ruby')
result = filters.apply(scope)
# Generates: WHERE tags.name LIKE '%programming%' AND documents.status = 'published' AND documents.title LIKE '%Ruby%'

# Filter by both document and tag attributes with different field names
class AdvancedDocumentFilters < Kiroshi::Filters
  filter_by :title, match: :like, table: :documents
  filter_by :tag_name, match: :like, table: :tags
  filter_by :category, table: :documents
  filter_by :tag_color, table: :tags
end

scope = Document.joins(:tags)
filters = AdvancedDocumentFilters.new(
  title: 'Ruby', 
  tag_name: 'tutorial', 
  category: 'programming',
  tag_color: 'blue'
)
result = filters.apply(scope)
# Generates: WHERE documents.title LIKE '%Ruby%' AND tags.name LIKE '%tutorial%' AND documents.category = 'programming' AND tags.color = 'blue'
```

The `table` parameter accepts both symbols and strings, and helps resolve column name ambiguity in complex joined queries.

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
scope = name_filter.apply(scope: scope, value: 'report')
scope = status_filter.apply(scope: scope, value: 'published')
```

#### Filter Options

- `match: :exact` - Performs exact matching (default)
- `match: :like` - Performs partial matching using SQL LIKE
- `table: :table_name` - Specifies which table to filter on (useful for joined queries)

```ruby
# Exact match filter
exact_filter = Kiroshi::Filter.new(:status)
exact_filter.apply(scope: Document.all, value: 'published')
# Generates: WHERE status = 'published'

# LIKE match filter
like_filter = Kiroshi::Filter.new(:title, match: :like)
like_filter.apply(scope: Document.all, value: 'Ruby')
# Generates: WHERE title LIKE '%Ruby%'

# Table-qualified filter for joined queries
tag_filter = Kiroshi::Filter.new(:name, match: :like, table: :tags)
tag_filter.apply(scope: Document.joins(:tags), value: 'programming')
# Generates: WHERE tags.name LIKE '%programming%'

# Document-specific filter in joined query
doc_filter = Kiroshi::Filter.new(:title, match: :exact, table: :documents)
doc_filter.apply(scope: Document.joins(:tags), value: 'Ruby Guide')
# Generates: WHERE documents.title = 'Ruby Guide'
```

#### Empty Value Handling

Filters automatically ignore empty or nil values:

```ruby
filter = Kiroshi::Filter.new(:name)
filter.apply(scope: Document.all, value: nil)        # Returns original scope
filter.apply(scope: Document.all, value: '')         # Returns original scope  
filter.apply(scope: Document.all, value: 'value')    # Applies filter
```

#### Handling Column Name Ambiguity

When working with joined tables that have columns with the same name, use the `table` parameter to specify which table's column to filter:

```ruby
# Without table specification - may cause ambiguity
scope = Document.joins(:tags)  # Both documents and tags have 'name' column

# Specify which table to filter on
name_filter = Kiroshi::Filter.new(:name, match: :like, table: :tags)
result = name_filter.apply(scope: scope, value: 'ruby')
# Generates: WHERE tags.name LIKE '%ruby%'

# Or filter by document name specifically
doc_name_filter = Kiroshi::Filter.new(:name, match: :like, table: :documents)
result = doc_name_filter.apply(scope: scope, value: 'guide')
# Generates: WHERE documents.name LIKE '%guide%'
```

**Priority**: When using `Kiroshi::Filters`, if a filter specifies a `table`, it takes priority over the scope's default table name.
