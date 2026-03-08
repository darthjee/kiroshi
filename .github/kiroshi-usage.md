# Using the Kiroshi Gem

**Kiroshi** is a Ruby gem that provides a declarative filtering system for ActiveRecord queries.
Instead of writing verbose `where` chains in controllers or service objects, Kiroshi lets you define
filter classes using a clean DSL, then apply them to any ActiveRecord scope.

- **Repository**: https://github.com/darthjee/kiroshi
- **YARD docs**: https://www.rubydoc.info/gems/kiroshi

---

## Installation

Add the gem to your `Gemfile` and run `bundle install`:

```ruby
gem 'kiroshi'
```

---

## Core Concepts

| Concept | Description |
|---------|-------------|
| `Kiroshi::Filters` | Base class – subclass it to define a set of filters for a model |
| `filter_by` | Class-level DSL method that registers a single filterable attribute |
| `#apply(scope)` | Instance method that receives an ActiveRecord scope and returns a filtered scope |

---

## Defining a Filter Class

Subclass `Kiroshi::Filters` and call `filter_by` for each attribute you want to make filterable:

```ruby
class DocumentFilters < Kiroshi::Filters
  filter_by :name,   match: :like
  filter_by :status
  filter_by :author, match: :like, table: :users, column: :name
end
```

### `filter_by` Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `match:` | Symbol | `:exact` | `:exact` for equality (`=`), `:like` for partial SQL `LIKE` |
| `table:` | Symbol/String | `nil` | Qualifies the column with a table name (useful for joined queries) |
| `column:` | Symbol | `nil` | Database column name when it differs from the filter key |

---

## Applying Filters

Instantiate the filter class with a hash of values and call `#apply` with an ActiveRecord scope:

```ruby
filters = DocumentFilters.new(name: 'report', status: 'published')
@documents = filters.apply(Document.all)
# => WHERE `documents`.`name` LIKE '%report%' AND `documents`.`status` = 'published'
```

- Keys may be symbols or strings.
- Blank or `nil` values are **automatically ignored** – no condition is added for them.

---

## Usage in Rails Controllers

```ruby
class DocumentsController < ApplicationController
  def index
    @documents = document_filters.apply(Document.all)
  end

  private

  def document_filters
    DocumentFilters.new(filter_params)
  end

  def filter_params
    params[:filter]&.permit(:name, :status, :author)
  end
end

class DocumentFilters < Kiroshi::Filters
  filter_by :name,   match: :like
  filter_by :status
  filter_by :author, match: :like, table: :users, column: :name
end
```

`ActionController::Parameters` objects are accepted directly without conversion.

---

## Partial Matching (LIKE)

Use `match: :like` to generate `WHERE column LIKE '%value%'` queries:

```ruby
class UserFilters < Kiroshi::Filters
  filter_by :email, match: :like
  filter_by :role                  # :exact is the default
end

filters = UserFilters.new(email: 'admin', role: 'moderator')
filters.apply(User.all)
# => WHERE `users`.`email` LIKE '%admin%' AND `users`.`role` = 'moderator'
```

---

## Joined Tables and Table Qualification

When a query joins multiple tables that share column names, use `table:` to avoid ambiguity:

```ruby
class DocumentFilters < Kiroshi::Filters
  filter_by :status                             # uses the scope's default table
  filter_by :tag_name, table: :tags             # always queries tags.tag_name
  filter_by :author,   table: :users, match: :like
end

scope = Document.joins(:tags, :user)
filters = DocumentFilters.new(tag_name: 'ruby', status: 'published', author: 'John')
filters.apply(scope)
# => WHERE `documents`.`status` = 'published'
#      AND `tags`.`tag_name` = 'ruby'
#      AND `users`.`author` LIKE '%John%'
```

---

## Custom Column Mapping

Use `column:` when the filter parameter name should differ from the actual database column:

```ruby
class DocumentFilters < Kiroshi::Filters
  filter_by :author_name, column: :name, table: :users, match: :like
  #           ^^^^^^^^^^^                ^^^^^
  #         filter key in params      real DB column
end

filters = DocumentFilters.new(author_name: 'John')
filters.apply(Document.joins(:user))
# => WHERE `users`.`name` LIKE '%John%'
```

---

## Filter Inheritance

Filter classes can inherit from other filter classes:

```ruby
class BaseDocumentFilters < Kiroshi::Filters
  filter_by :status
  filter_by :category
end

class AdvancedDocumentFilters < BaseDocumentFilters
  filter_by :name,   match: :like
  filter_by :author, match: :like, table: :users, column: :name
end

# AdvancedDocumentFilters applies all four filters
filters = AdvancedDocumentFilters.new(status: 'published', name: 'ruby')
filters.apply(Document.all)
```

---

## Complete Example

```ruby
# app/filters/article_filters.rb
class ArticleFilters < Kiroshi::Filters
  filter_by :title,      match: :like
  filter_by :status
  filter_by :category
  filter_by :tag_name,   match: :like, table: :tags
  filter_by :author_name, column: :name, table: :users, match: :like
end

# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def index
    @articles = article_filters.apply(Article.joins(:tags, :user))
  end

  private

  def article_filters
    ArticleFilters.new(filter_params)
  end

  def filter_params
    params[:filter]&.permit(:title, :status, :category, :tag_name, :author_name)
  end
end
```

Request: `GET /articles?filter[title]=ruby&filter[status]=published&filter[tag_name]=tutorial`

Generated SQL (simplified):
```sql
WHERE `articles`.`title` LIKE '%ruby%'
  AND `articles`.`status` = 'published'
  AND `tags`.`tag_name` LIKE '%tutorial%'
```
