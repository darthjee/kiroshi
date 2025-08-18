# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::FilterQuery::Like, type: :model do
  describe '#apply' do
    subject(:query) { described_class.new(filter_runner) }

    let(:filter_runner) { Kiroshi::FilterRunner.new(filter: filter, scope: scope, filters: filters) }
    let(:filter)        { Kiroshi::Filter.new(:name, match: :like) }
    let(:scope)         { Document.all }
    let(:filter_value)  { 'test' }
    let(:filters)       { { name: filter_value } }

    let!(:matching_document)     { create(:document, name: 'test_document') }
    let!(:another_match)         { create(:document, name: 'my_test_file') }
    let!(:non_matching_document) { create(:document, name: 'other_document') }

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
      expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE (documents.name LIKE '%test%')"
      expect(query.apply.to_sql).to eq(expected_sql)
    end

    context 'when filtering by status attribute' do
      let(:filter)        { Kiroshi::Filter.new(:status, match: :like) }
      let(:filter_value)  { 'pub' }
      let(:filters)       { { status: filter_value } }

      let!(:published_document)     { create(:document, status: 'published') }
      let!(:republished_document)   { create(:document, status: 'republished') }
      let!(:draft_document)         { create(:document, status: 'draft') }

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
        expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE (documents.status LIKE '%pub%')"
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filtering with numeric values as strings' do
      let(:filter)        { Kiroshi::Filter.new(:version, match: :like) }
      let(:filter_value)  { '1.2' }
      let(:filters)       { { version: filter_value } }

      let!(:version_match)     { create(:document, version: '1.2.3') }
      let!(:another_version)   { create(:document, version: '2.1.2') }
      let!(:different_version) { create(:document, version: '3.0.0') }

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
        expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE (documents.version LIKE '%1.2%')"
        expect(query.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when no records match' do
      let(:filter_value) { 'nonexistent' }

      it 'returns empty relation' do
        expect(query.apply).to be_empty
      end

      it 'still generates valid SQL' do
        expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE (documents.name LIKE '%nonexistent%')"
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
      let(:filter_value)           { 'user@' }
      let!(:email_document)        { create(:document, name: 'user@example.com') }
      let!(:partial_email_document) { create(:document, name: 'admin_user@test.org') }
      let!(:no_match_document)     { create(:document, name: 'username') }

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
  end
end
