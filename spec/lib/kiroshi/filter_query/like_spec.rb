# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::FilterQuery::Like, type: :model do
  describe '#apply' do
    subject(:query) { described_class.new(filter_runner) }

    let(:filter_runner) { Kiroshi::FilterRunner.new(filter: filter, scope: scope, value: filter_value) }
    let(:filter)        { Kiroshi::Filter.new(:name, match: :like) }
    let(:scope)         { Document.all }
    let(:filter_value)  { 'test' }

    let!(:matching_document)     { create(:document, name: 'test_document') }
    let!(:another_match)         { create(:document, name: 'my_test_file') }
    let!(:non_matching_document) { create(:document, name: 'other_document') }

    let(:expected_sql) do
      <<~SQL.squish
        SELECT "documents".* FROM "documents" WHERE ("documents"."name" LIKE '%test%')
      SQL
    end

    it 'returns records that partially match the filter value' do
      expect(query.apply).to include(matching_document)
    end

    it 'returns multiple records that contain the filter value' do
      expect(query.apply).to include(another_match)
    end

    it 'does not return records that do not contain the filter value' do
      expect(query.apply).not_to include(non_matching_document)
    end

    it 'generates correct SQL with LIKE operation' do
      expect(query.apply.to_sql).to eq(expected_sql)
    end

    context 'when filtering by status attribute' do
      let(:filter)        { Kiroshi::Filter.new(:status, match: :like) }
      let(:filter_value)  { 'pub' }

      let!(:published_document)     { create(:document, status: 'published') }
      let!(:republished_document)   { create(:document, status: 'republished') }
      let!(:draft_document)         { create(:document, status: 'draft') }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE ("documents"."status" LIKE '%pub%')
        SQL
      end

      it 'returns documents with partial status match' do
        expect(query.apply).to include(published_document)
      end

      it 'returns documents with partial match in different positions' do
        expect(query.apply).to include(republished_document)
      end

      it 'does not return documents without partial status match' do
        expect(query.apply).not_to include(draft_document)
      end

      it 'generates correct SQL for status filtering' do
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filtering with numeric values as strings' do
      let(:filter)        { Kiroshi::Filter.new(:version, match: :like) }
      let(:filter_value)  { '1.2' }

      let!(:version_match)     { create(:document, version: '1.2.3') }
      let!(:another_version)   { create(:document, version: '2.1.2') }
      let!(:different_version) { create(:document, version: '3.0.0') }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE ("documents"."version" LIKE '%1.2%')
        SQL
      end

      it 'returns documents with partial numeric match' do
        expect(query.apply).to include(version_match)
      end

      it 'returns documents with partial match in different positions' do
        expect(query.apply).to include(another_version)
      end

      it 'does not return documents without partial numeric match' do
        expect(query.apply).not_to include(different_version)
      end

      it 'generates correct SQL for numeric string filtering' do
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when no records match' do
      let(:filter_value) { 'nonexistent' }

      let(:expected_sql) do
        <<~SQL.squish
          SELECT "documents".* FROM "documents" WHERE ("documents"."name" LIKE '%nonexistent%')
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
      let(:filter_value)        { 'Test' }
      let!(:lowercase_document) { create(:document, name: 'test_document') }
      let!(:uppercase_document) { create(:document, name: 'TEST_FILE') }
      let!(:mixedcase_document) { create(:document, name: 'Test_Document') }
      let!(:no_match_document)  { create(:document, name: 'example') }

      it 'includes documents with exact case match' do
        expect(query.apply).to include(mixedcase_document)
      end

      it 'includes documents with lowercase match' do
        expect(query.apply).to include(lowercase_document)
      end

      it 'includes documents with uppercase match' do
        expect(query.apply).to include(uppercase_document)
      end

      it 'excludes documents without any case match' do
        expect(query.apply).not_to include(no_match_document)
      end
    end

    context 'with special characters in filter value' do
      let(:filter_value) { 'user@' }
      let!(:email_document)         { create(:document, name: 'user@example.com') }
      let!(:partial_email_document) { create(:document, name: 'admin_user@test.org') }
      let!(:no_match_document)      { create(:document, name: 'username') }

      it 'includes documents with special character match' do
        expect(query.apply).to include(email_document)
      end

      it 'includes documents with partial special character match' do
        expect(query.apply).to include(partial_email_document)
      end

      it 'excludes documents without special character match' do
        expect(query.apply).not_to include(no_match_document)
      end
    end

    context 'with single character filter' do
      let(:filter_value)       { 'a' }
      let!(:start_match)       { create(:document, name: 'apple') }
      let!(:middle_match)      { create(:document, name: 'banana') }
      let!(:end_match)         { create(:document, name: 'extra') }
      let!(:no_match_document) { create(:document, name: 'test') }

      it 'includes documents with character at start' do
        expect(query.apply).to include(start_match)
      end

      it 'includes documents with character in middle' do
        expect(query.apply).to include(middle_match)
      end

      it 'includes documents with character at end' do
        expect(query.apply).to include(end_match)
      end

      it 'excludes documents without the character' do
        expect(query.apply).not_to include(no_match_document)
      end
    end

    context 'when filter has table configured' do
      let(:scope) { Document.joins(:tags) }
      let(:filter_value) { 'ruby' }

      let!(:first_tag) { Tag.find_or_create_by(name: 'ruby') }
      let!(:second_tag) { Tag.find_or_create_by(name: 'ruby_on_rails') }

      let!(:document_with_ruby_tag) { create(:document, name: 'My Document') }
      let!(:document_with_rails_tag) { create(:document, name: 'Rails Guide') }
      let!(:document_without_tag)    { create(:document, name: 'Other Document') }

      before do
        Tag.find_or_create_by(name: 'programming')
        document_with_ruby_tag.tags << [first_tag]
        document_with_rails_tag.tags << [second_tag]
      end

      context 'when filtering by tags table' do
        let(:filter) { Kiroshi::Filter.new(:name, match: :like, table: :tags) }

        it 'returns documents with tags that partially match the filter value' do
          expect(query.apply).to include(document_with_ruby_tag)
        end

        it 'returns documents with tags that contain the filter value' do
          expect(query.apply).to include(document_with_rails_tag)
        end

        it 'does not return documents without matching tags' do
          expect(query.apply).not_to include(document_without_tag)
        end

        it 'generates SQL with tags table qualification' do
          result_sql = query.apply.to_sql
          expect(result_sql).to include('"tags"."name" LIKE')
        end

        it 'generates SQL with correct LIKE pattern for tag name' do
          result_sql = query.apply.to_sql
          expect(result_sql).to include("'%ruby%'")
        end
      end

      context 'when filtering by documents table explicitly' do
        let(:filter)       { Kiroshi::Filter.new(:name, match: :like, table: :documents) }
        let(:filter_value) { 'Guide' }

        it 'returns documents that partially match the filter value in document name' do
          expect(query.apply).to include(document_with_rails_tag)
        end

        it 'does not return documents that do not match document name' do
          expect(query.apply).not_to include(document_with_ruby_tag)
        end

        it 'does not return documents without matching document name' do
          expect(query.apply).not_to include(document_without_tag)
        end

        it 'generates SQL with documents table qualification' do
          result_sql = query.apply.to_sql
          expect(result_sql).to include('"documents"."name" LIKE')
        end

        it 'generates SQL with correct LIKE pattern for document name' do
          result_sql = query.apply.to_sql
          expect(result_sql).to include("'%Guide%'")
        end
      end

      context 'when table is specified as string' do
        let(:filter) { Kiroshi::Filter.new(:name, match: :like, table: 'tags') }

        it 'works the same as with symbol table name' do
          expect(query.apply).to include(document_with_ruby_tag)
        end

        it 'generates SQL with string table qualification' do
          result_sql = query.apply.to_sql
          expect(result_sql).to include('"tags"."name" LIKE')
        end
      end
    end
  end
end
