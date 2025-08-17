# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::Filter, type: :model do
  describe '#apply' do
    let(:scope) { Document.all }
    let(:filter_value) { 'test_value' }
    let(:filters) { { name: filter_value } }
    let!(:matching_document) { create(:document, name: filter_value) }
    let!(:non_matching_document) { create(:document, name: 'other_value') }

    context 'when match is :exact' do
      subject(:filter) { described_class.new(:name, match: :exact) }

      it 'returns exact matches' do
        expect(filter.apply(scope, filters)).to include(matching_document)
      end

      it 'does not return non-matching records' do
        expect(filter.apply(scope, filters)).not_to include(non_matching_document)
      end
    end

    context 'when match is :like' do
      subject(:filter) { described_class.new(:name, match: :like) }

      let(:filter_value) { 'test' }
      let!(:matching_document) { create(:document, name: 'test_document') }
      let!(:non_matching_document) { create(:document, name: 'other_value') }

      it 'returns partial matches' do
        expect(filter.apply(scope, filters)).to include(matching_document)
      end

      it 'does not return non-matching records' do
        expect(filter.apply(scope, filters)).not_to include(non_matching_document)
      end
    end

    context 'when match is not specified (default)' do
      subject(:filter) { described_class.new(:name) }

      it 'defaults to exact match returning only exact matches' do
        expect(filter.apply(scope, filters)).to include(matching_document)
      end

      it 'defaults to exact match returning not returning when filtering by a non-matching value' do
        expect(filter.apply(scope, filters)).not_to include(non_matching_document)
      end
    end

    context 'when filter value is not present' do
      subject(:filter) { described_class.new(:name) }

      let(:filters) { { name: nil } }

      it 'returns the original scope unchanged' do
        expect(filter.apply(scope, filters)).to eq(scope)
      end
    end
  end
end
