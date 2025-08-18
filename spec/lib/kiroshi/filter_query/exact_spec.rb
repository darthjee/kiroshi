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

    it 'generates correct SQL with exact equality' do
      expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE \"documents\".\"name\" = 'test_document'"
      expect(query.apply.to_sql).to eq(expected_sql)
    end

    context 'when filtering by status attribute' do
      let(:filter)        { Kiroshi::Filter.new(:status, match: :exact) }
      let(:filter_value)  { 'published' }
      let(:filters)       { { status: filter_value } }

      let!(:published_document) { create(:document, status: 'published') }
      let!(:draft_document)     { create(:document, status: 'draft') }

      it 'returns documents with exact status match' do
        expect(query.apply).to include(published_document)
      end

      it 'does not return documents without exact status match' do
        expect(query.apply).not_to include(draft_document)
      end

      it 'generates correct SQL for status filtering' do
        expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE \"documents\".\"status\" = 'published'"
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filtering with numeric values' do
      let(:filter)        { Kiroshi::Filter.new(:priority, match: :exact) }
      let(:filter_value)  { 1 }
      let(:filters)       { { priority: filter_value } }

      let!(:high_priority_document)   { create(:document, priority: 1) }
      let!(:medium_priority_document) { create(:document, priority: 2) }

      it 'returns documents with exact numeric match' do
        expect(query.apply).to include(high_priority_document)
      end

      it 'does not return documents without exact numeric match' do
        expect(query.apply).not_to include(medium_priority_document)
      end

      it 'generates correct SQL for numeric filtering' do
        expected_sql = 'SELECT "documents".* FROM "documents" WHERE "documents"."priority" = 1'
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filtering with boolean values' do
      let(:filter)        { Kiroshi::Filter.new(:active, match: :exact) }
      let(:filter_value)  { true }
      let(:filters)       { { active: filter_value } }

      let!(:active_document)   { create(:document, active: true) }
      let!(:inactive_document) { create(:document, active: false) }

      it 'returns documents with exact boolean match' do
        expect(query.apply).to include(active_document)
      end

      it 'does not return documents without exact boolean match' do
        expect(query.apply).not_to include(inactive_document)
      end

      it 'generates correct SQL for boolean filtering' do
        expected_sql = 'SELECT "documents".* FROM "documents" WHERE "documents"."active" = 1'
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when no records match' do
      let(:filter_value) { 'nonexistent_value' }

      it 'returns empty relation' do
        expect(query.apply).to be_empty
      end

      it 'still generates valid SQL' do
        expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE \"documents\".\"name\" = 'nonexistent_value'"
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
  end
end
