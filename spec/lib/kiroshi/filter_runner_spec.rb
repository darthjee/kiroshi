# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::FilterRunner, type: :model do
  describe '#apply' do
    subject(:runner) { described_class.new(filter: filter, scope: scope, filters: filters) }

    let(:scope)                  { Document.all }
    let(:filter_value)           { 'test_value' }
    let(:filters)                { { name: filter_value } }
    let!(:matching_document)     { create(:document, name: filter_value) }
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
      let(:filter)  { Kiroshi::Filter.new(:name) }
      let(:filters) { { name: nil } }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'when filter value is empty string' do
      let(:filter) { Kiroshi::Filter.new(:name) }
      let(:filters) { { name: '' } }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'when filter attribute is not in filters hash' do
      let(:filter) { Kiroshi::Filter.new(:status) }
      let(:filters) { { name: 'test_value' } }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'when filters hash is empty' do
      let(:filter) { Kiroshi::Filter.new(:name) }
      let(:filters) { {} }

      it 'returns the original scope unchanged' do
        expect(runner.apply).to eq(scope)
      end
    end

    context 'with multiple attributes' do
      let(:filter) { Kiroshi::Filter.new(:status, match: :exact) }
      let(:filters)                { { name: 'test_name', status: 'finished' } }
      let!(:matching_document)     { create(:document, name: 'test_name', status: 'finished') }
      let!(:non_matching_document) { create(:document, name: 'other_name', status: 'processing') }

      it 'filters by the configured attribute only' do
        result = runner.apply
        expect(result).to include(matching_document)
        expect(result).not_to include(non_matching_document)
      end
    end
  end
end
