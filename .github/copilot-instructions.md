# Copilot Instructions for Kiroshi

## Project Overview

**Kiroshi** is a Ruby gem that provides a declarative filtering system for ActiveRecord queries.
Instead of writing verbose, repetitive `where` chains in controllers or service objects, Kiroshi lets
you define filter classes using a clean DSL. When a request arrives, Kiroshi reads the relevant
parameters and applies the appropriate `where` conditions and response-content filters automatically.

### Core Concepts

- **`Kiroshi::Filters`** – Base class for defining a set of filters. Subclass it and use `filter_by`
  to declare each filterable attribute.
- **`filter_by`** – Class-level DSL method that registers a filter. Supports `:exact` (default) and
  `:like` matching, optional `table:` qualification for joined queries, and optional `column:` mapping
  when the filter key differs from the database column name.
- **`#apply(scope)`** – Instance method that receives an ActiveRecord scope and returns a new scope
  with all present (non-blank) filters applied.

### Quick Example

```ruby
class DocumentFilters < Kiroshi::Filters
  filter_by :name,   match: :like
  filter_by :status
  filter_by :author, match: :like, table: :users, column: :name
end

# In a controller:
def index
  @documents = DocumentFilters.new(filter_params).apply(Document.all)
end
```

---

## Language

All **code**, **comments**, **documentation**, **commit messages**, **PR titles and descriptions**, and
**issue/review comments** must be written in **English**.

---

## Testing

- Every new class and every new public method must have a corresponding RSpec spec.
- Specs live under `spec/` mirroring the `lib/` structure (e.g., `lib/kiroshi/filter.rb` →
  `spec/lib/kiroshi/filter_spec.rb`).
- Use `let`, `subject`, `context`, and `describe` following the existing patterns in the spec suite.
- Use [FactoryBot](https://github.com/thoughtbot/factory_bot) for model fixtures when database
  records are required.
- Write specs that cover edge cases: empty/nil parameters, string vs symbol keys, joined table
  scenarios, etc.
- If a file under `lib/` has **no spec file**, add it to **`config/check_specs.yml`** under the
  `ignore:` key. Keep this list as short as possible; prefer writing tests over ignoring files.

---

## Documentation

- All public classes and public methods must have [YARD](https://yardoc.org/) documentation.
- Required tags: `@api public` / `@api private`, `@param`, `@return`, `@example`, `@since`.
  - Add `@note` when behaviour is non-obvious.
- The project enforces **100% YARD coverage** via `bundle exec rake verify_measurements` (see
  `config/yardstick.yml`). Every new piece of public API must satisfy this threshold.
- Keep summaries on a single line and end them with a period.

---

## Code Style & Design Principles

### Small Classes and Methods (Sandi Metz / *99 Bottles of OOP*)

- A class should have **one reason to change** (Single Responsibility Principle).
- Methods should be **short** (aim for ≤ 5 lines) and do **one thing**.
- Classes should be **small** (aim for ≤ 100 lines, excluding documentation).
- Prefer extracting collaborator objects over adding conditional logic to existing classes.
- Name every abstraction clearly; if naming is hard, the abstraction is probably wrong.

### Law of Demeter

- An object should only call methods on:
  - `self`
  - objects it owns (instance variables)
  - objects passed in as arguments
  - objects it creates directly
- Avoid chains like `a.b.c.d`. If a chain is necessary, introduce a delegation method or a
  dedicated value object.

### General Guidelines

- Add `# frozen_string_literal: true` to every Ruby file.
- Prefer keyword arguments for methods with multiple optional parameters.
- Keep `private` methods clearly separated and well-documented with `@api private`.
- Avoid monkey-patching and reopening core classes.
- Follow the conventions already established in the codebase (lazy initialisation with `||=`,
  simple delegation via `attr_reader`, etc.).
