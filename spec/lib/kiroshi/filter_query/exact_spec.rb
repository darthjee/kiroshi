# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::FilterQuery::Exact, type: :model do
  describe '#apply' do
    subject(:query) { described_class.new(filter_runner) }

    let(:filter_runner) { Kiroshi::FilterRunner.new(filter: filter, scope: scope, filters: filters) }
    let(:filter)        { Kiroshi::Filter.new(:name, match: :exact) }
    let(:scope)         { Document.all }
    let(:filter_value)  { 'test_document' }
    let(:filters)       { { name: filter_value } }

    let!(:matching_document)     { create(:document, name: 'test_document') }
    let!(:non_matching_document) { create(:document, name: 'other_document') }

    it 'returns records that exactly match the filter value' do
      expect(query.apply).to include(matching_document)
    end

    it 'does not return records that do not exactly match' do
      expect(query.apply).not_to include(non_matching_document)
    end

    let(:expected_sql) do
      <<~SQL.squish
        SELECT "documents".* FROM "documents" WHERE "documents"."name" = 'test_document'
      SQL
    end

    it 'generates correct SQL with exact equality' do
      expect(query.apply.to_sql).to eq(expected_sql)
    end

    context 'when filtering by status attribute' do
      let(:filter)        { Kiroshi::Filter.new(:status, match: :exact) }
      let(:filter_value)  { 'published' }
      let(:filters)       { { status: filter_value } }

      let!(:published_document) { create(:document, status: 'published') }
      let!(:draft_document)     { create(:document, status: 'draft') }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE "documents"."status" = 'published'
        SQL
      end

      it 'returns documents with exact status match' do
        expect(query.apply).to include(published_document)
      end

      it 'does not return documents without exact status match' do
        expect(query.apply).not_to include(draft_document)
      end

      it 'generates correct SQL for status filtering' do
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filtering with numeric values' do
      let(:filter)        { Kiroshi::Filter.new(:priority, match: :exact) }
      let(:filter_value)  { 1 }
      let(:filters)       { { priority: filter_value } }

      let!(:high_priority_document)   { create(:document, priority: 1) }
      let!(:medium_priority_document) { create(:document, priority: 2) }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE "documents"."priority" = 1
        SQL
      end

      it 'returns documents with exact numeric match' do
        expect(query.apply).to include(high_priority_document)
      end

      it 'does not return documents without exact numeric match' do
        expect(query.apply).not_to include(medium_priority_document)
      end

      it 'generates correct SQL for numeric filtering' do
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filtering with boolean values' do
      let(:filter)        { Kiroshi::Filter.new(:active, match: :exact) }
      let(:filter_value)  { true }
      let(:filters)       { { active: filter_value } }

      let!(:active_document)   { create(:document, active: true) }
      let!(:inactive_document) { create(:document, active: false) }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE "documents"."active" = 1
        SQL
      end

      it 'returns documents with exact boolean match' do
        expect(query.apply).to include(active_document)
      end

      it 'does not return documents without exact boolean match' do
        expect(query.apply).not_to include(inactive_document)
      end

      it 'generates correct SQL for boolean filtering' do
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when no records match' do
      let(:filter_value) { 'nonexistent_value' }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE "documents"."name" = 'nonexistent_value'
        SQL
      end

      it 'returns empty relation' do
        expect(query.apply).to be_empty
      end

      it 'still generates valid SQL' do
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'with case sensitivity' do
      let(:filter_value)        { 'Test_Document' }
      let!(:lowercase_document) { create(:document, name: 'test_document') }
      let!(:uppercase_document) { create(:document, name: 'TEST_DOCUMENT') }
      let!(:mixedcase_document) { create(:document, name: 'Test_Document') }

      it 'includes documents with exact case match' do
        expect(query.apply).to include(mixedcase_document)
      end

      it 'excludes documents with lowercase' do
        expect(query.apply).not_to include(lowercase_document)
      end

      it 'excludes documents with upcase' do
        expect(query.apply).not_to include(uppercase_document)
      end
    end

    context 'when filter has table configured' do
      let(:scope) { Document.joins(:tags) }
      let(:filter_value) { 'ruby' }
      let(:filters)      { { name: filter_value } }

      let!(:first_tag) { Tag.find_or_create_by(name: 'ruby') }
      let!(:second_tag) { Tag.find_or_create_by(name: 'programming') }
      let!(:third_tag)  { Tag.find_or_create_by(name: 'javascript') }

      let!(:document_with_ruby_tag) { create(:document, name: 'My Document') }
      let!(:document_with_js_tag) { create(:document, name: 'JS Guide') }
      let!(:document_without_tag) { create(:document, name: 'Other Document') }

      before do
        document_with_ruby_tag.tags << [first_tag]
        document_with_js_tag.tags << [third_tag]
      end

      context 'when filtering by tags table' do
        let(:filter) { Kiroshi::Filter.new(:name, match: :exact, table: :tags) }

        let(:expected_sql) do
          <<~SQL.squish
            SELECT "documents".* FROM "documents" 
            INNER JOIN "documents_tags" ON "documents_tags"."document_id" = "documents"."id" 
            INNER JOIN "tags" ON "tags"."id" = "documents_tags"."tag_id" 
            WHERE "tags"."name" = 'ruby'
          SQL
        end

        it 'returns documents with tags that exactly match the filter value' do
          expect(query.apply).to include(document_with_ruby_tag)
        end

        it 'does not return documents with tags that do not exactly match' do
          expect(query.apply).not_to include(document_with_js_tag)
        end

        it 'does not return documents without matching tags' do
          expect(query.apply).not_to include(document_without_tag)
        end

        it 'generates SQL with tags table qualification' do
          expect(query.apply.to_sql).to eq(expected_sql)
        end
      end

      context 'when filtering by documents table explicitly' do
        let(:filter)       { Kiroshi::Filter.new(:name, match: :exact, table: :documents) }
        let(:filter_value) { 'JS Guide' }

        let(:expected_sql) do
          <<~SQL.squish
            SELECT "documents".* FROM "documents" 
            INNER JOIN "documents_tags" ON "documents_tags"."document_id" = "documents"."id" 
            INNER JOIN "tags" ON "tags"."id" = "documents_tags"."tag_id" 
            WHERE "documents"."name" = 'JS Guide'
          SQL
        end

        it 'returns documents that exactly match the filter value in document name' do
          expect(query.apply).to include(document_with_js_tag)
        end

        it 'does not return documents that do not exactly match document name' do
          expect(query.apply).not_to include(document_with_ruby_tag)
        end

        it 'does not return documents without exact document name match' do
          expect(query.apply).not_to include(document_without_tag)
        end

        it 'generates SQL with documents table qualification' do
          expect(query.apply.to_sql).to eq(expected_sql)
        end
      end

      context 'when table is specified as string' do
        let(:filter) { Kiroshi::Filter.new(:name, match: :exact, table: 'tags') }

        let(:expected_sql) do
          <<~SQL.squish
            SELECT "documents".* FROM "documents" 
            INNER JOIN "documents_tags" ON "documents_tags"."document_id" = "documents"."id" 
            INNER JOIN "tags" ON "tags"."id" = "documents_tags"."tag_id" 
            WHERE "tags"."name" = 'ruby'
          SQL
        end

        it 'works the same as with symbol table name' do
          expect(query.apply).to include(document_with_ruby_tag)
        end

        it 'generates SQL with string table qualification' do
          expect(query.apply.to_sql).to eq(expected_sql)
        end
      end

      context 'when filtering by different attributes with table qualification' do
        let(:filter)       { Kiroshi::Filter.new(:id, match: :exact, table: :tags) }
        let(:filter_value) { first_tag.id }
        let(:filters)      { { id: filter_value } }

        let(:expected_sql) do
          <<~SQL.squish
            SELECT "documents".* FROM "documents" 
            INNER JOIN "documents_tags" ON "documents_tags"."document_id" = "documents"."id" 
            INNER JOIN "tags" ON "tags"."id" = "documents_tags"."tag_id" 
            WHERE "tags"."id" = #{first_tag.id}
          SQL
        end

        it 'returns documents with tags that match the tag id' do
          expect(query.apply).to include(document_with_ruby_tag)
        end

        it 'does not return documents without the matching tag id' do
          expect(query.apply).not_to include(document_with_js_tag)
        end

        it 'generates SQL with tags table qualification for id attribute' do
          expect(query.apply.to_sql).to eq(expected_sql)
        end
      end
    end
  end
end
