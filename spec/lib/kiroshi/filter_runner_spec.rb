# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::FilterRunner, type: :model do
  describe '#apply' do
    subject(:runner) { described_class.new(filter: filter, scope: scope, value: filter_value) }

    let(:scope)                  { Document.all }
    let(:filter_value)           { 'test_value' }
    let(:document_name)          { filter_value }
    let!(:matching_document)     { create(:document, name: document_name) }
    let!(:non_matching_document) { create(:document, name: 'other_value') }

    context 'when filter match is :exact' do
      let(:filter) { Kiroshi::Filter.new(:name, match: :exact) }

      it 'returns exact matches' do
        expect(runner.apply).to include(matching_document)
      end

      it 'does not return non-matching records' do
        expect(runner.apply).not_to include(non_matching_document)
      end
    end

    context 'when filter match is :like' do
      let(:filter)                 { Kiroshi::Filter.new(:name, match: :like) }
      let(:filter_value)           { 'test' }
      let!(:matching_document)     { create(:document, name: 'test_document') }
      let!(:non_matching_document) { create(:document, name: 'other_value') }

      it 'returns partial matches' do
        expect(runner.apply).to include(matching_document)
      end

      it 'does not return non-matching records' do
        expect(runner.apply).not_to include(non_matching_document)
      end

      it 'generates correct SQL with table name prefix' do
        expected_sql = "SELECT \"documents\".* FROM \"documents\" WHERE (documents.name LIKE '%test%')"
        expect(runner.apply.to_sql).to eq(expected_sql)
      end
    end

    context 'when filter match is not specified (default)' do
      let(:filter) { Kiroshi::Filter.new(:name) }

      it 'defaults to exact match returning only exact matches' do
        expect(runner.apply).to include(matching_document)
      end

      it 'defaults to exact match not returning non-matching records' do
        expect(runner.apply).not_to include(non_matching_document)
      end
    end

    context 'when filter value is not present' do
      let(:document_name) { 'Some name' }
      let(:filter)        { Kiroshi::Filter.new(:name) }
      let(:filter_value)  { nil }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'when filter value is empty string' do
      let(:document_name) { 'Some name' }
      let(:filter)       { Kiroshi::Filter.new(:name) }
      let(:filter_value) { '' }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'when filter value is blank' do
      let(:document_name) { 'Some name' }
      let(:filter)       { Kiroshi::Filter.new(:name) }
      let(:filter_value) { nil }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'with status filter' do
      let(:filter)                 { Kiroshi::Filter.new(:status, match: :exact) }
      let(:filter_value)           { 'finished' }
      let!(:matching_document)     { create(:document, name: 'test_name', status: 'finished') }
      let!(:non_matching_document) { create(:document, name: 'other_name', status: 'processing') }

      it 'filters by the configured attribute only returning the matched' do
        expect(runner.apply).to include(matching_document)
      end

      it 'does not return non-matching records' do
        expect(runner.apply).not_to include(non_matching_document)
      end
    end
  end
end
