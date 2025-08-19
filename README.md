# Kiroshi
[![Build Status](https://circleci.com/gh/darthjee/kiroshi.svg?style=shield)](https://circleci.com/gh/darthjee/kiroshi)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/35480a5e82e74ff7a0186697b3f61a4b)](https://app.codacy.com/gh/darthjee/kiroshi/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)

![kiroshi](https://raw.githubusercontent.com/darthjee/kiroshi/master/kiroshi.jpg)


## Yard Documentation

[https://www.rubydoc.info/gems/kiroshi/0.3.1](https://www.rubydoc.info/gems/kiroshi/0.3.1)

Kiroshi has been designed to make filtering ActiveRecord queries easier
by providing a flexible and reusable filtering system. It allows you to
define filter sets that can be applied to any ActiveRecord scope,
supporting both exact matches and partial matching using SQL LIKE operations.

Current Release: [0.3.1](https://github.com/darthjee/kiroshi/tree/0.3.1)

[Next release](https://github.com/darthjee/kiroshi/compare/0.3.1...master)

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

<details>
<summary>Specifying filter types</summary>

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
</details>

#### Advanced Examples

##### Multiple Filter Types

<details>
<summary>Applying only some filters</summary>

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
</details>

##### Controller Integration

<details>
<summary>Using filters in Rails controllers</summary>

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
</details>

##### Nested Resource Filtering

<details>
<summary>Filtering nested resources</summary>

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
</details>

##### Joined Tables and Table Qualification

<details>
<summary>Working with joined tables</summary>

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
</details>

###### Table Qualification Examples

<details>
<summary>Advanced table qualification scenarios</summary>

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
</details>

##### Custom Column Mapping

<details>
<summary>Using different filter keys from database columns</summary>

Sometimes you may want to use a different filter key name from the database column name. The `column` parameter allows you to specify which database column to query while keeping a descriptive filter key:

```ruby
class UserFilters < Kiroshi::Filters
  filter_by :full_name, column: :name, match: :like      # Filter key 'full_name' queries 'name' column
  filter_by :user_email, column: :email, match: :like    # Filter key 'user_email' queries 'email' column  
  filter_by :account_status, column: :status             # Filter key 'account_status' queries 'status' column
end

filters = UserFilters.new(full_name: 'John', user_email: 'admin', account_status: 'active')
result = filters.apply(User.all)
# Generates: WHERE name LIKE '%John%' AND email LIKE '%admin%' AND status = 'active'
```
</details>

###### Column Mapping with Table Qualification

<details>
<summary>Combining column mapping with table qualification</summary>

You can combine `column` and `table` parameters for complex scenarios:

```ruby
class DocumentFilters < Kiroshi::Filters
  filter_by :author_name, column: :name, table: :users, match: :like  # Filter key 'author_name' queries 'users.name'
  filter_by :doc_title, column: :title, table: :documents, match: :like  # Filter key 'doc_title' queries 'documents.title'
  filter_by :tag_label, column: :name, table: :tags, match: :like     # Filter key 'tag_label' queries 'tags.name'
end

scope = Document.joins(:user, :tags)
filters = DocumentFilters.new(author_name: 'John', doc_title: 'Ruby', tag_label: 'tutorial')
result = filters.apply(scope)
# Generates: WHERE users.name LIKE '%John%' AND documents.title LIKE '%Ruby%' AND tags.name LIKE '%tutorial%'
```

This feature is particularly useful when:
- Creating more descriptive filter parameter names for APIs
- Avoiding naming conflicts between filter keys and existing method names
- Building user-friendly filter interfaces with intuitive parameter names
</details>

## API Reference

Kiroshi provides a simple, clean API focused on the `Kiroshi::Filters` class. Individual filters are handled internally and don't require direct interaction in most use cases.
