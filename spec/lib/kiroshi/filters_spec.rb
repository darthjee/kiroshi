# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::Filters, type: :model do
  subject(:filters_class) { Class.new(described_class) }

  let(:filter_instance) { filters_class.new(filters) }
  let(:scope)           { Document.all }
  let(:filters)         { {} }

  describe '#apply' do
    let!(:document)       { create(:document, name: 'test_name', status: 'finished') }
    let!(:other_document) { create(:document, name: 'other_name', status: 'processing') }

    context 'when no filters are configured' do
      context 'when no filters are provided' do
        it 'returns the original scope unchanged' do
          expect(filter_instance.apply(scope)).to eq(scope)
        end
      end

      context 'when filters are provided' do
        let(:filters) { { name: 'test_name' } }

        it 'returns the original scope unchanged' do
          expect(filter_instance.apply(scope)).to eq(scope)
        end
      end
    end

    context 'when one exact filter is configured' do
      let(:filters) { { name: 'test_name' } }

      before do
        filters_class.filter_by :name
      end

      it 'returns documents matching the exact filter' do
        expect(filter_instance.apply(scope)).to include(document)
      end

      it 'does not return documents not matching the exact filter' do
        expect(filter_instance.apply(scope)).not_to include(other_document)
      end
    end

    context 'when one like filter is configured' do
      let(:filters) { { name: 'test' } }

      before do
        filters_class.filter_by :name, match: :like
      end

      it 'returns documents matching the like filter' do
        expect(filter_instance.apply(scope)).to include(document)
      end

      it 'does not return documents not matching the like filter' do
        expect(filter_instance.apply(scope)).not_to include(other_document)
      end
    end

    context 'when multiple filters are configured' do
      let(:filters) { { name: 'test', status: 'finished' } }

      before do
        filters_class.filter_by :name, match: :like
        filters_class.filter_by :status
      end

      it 'returns documents matching all filters' do
        expect(filter_instance.apply(scope)).to include(document)
      end

      it 'does not return documents not matching all filters' do
        expect(filter_instance.apply(scope)).not_to include(other_document)
      end
    end

    context 'when filters hash is empty' do
      before do
        filters_class.filter_by :name
        filters_class.filter_by :status
      end

      let(:filters) { {} }

      it 'returns the original scope unchanged' do
        expect(filter_instance.apply(scope)).to eq(scope)
      end
    end

    context 'when scope has joined tables with clashing fields' do
      let(:scope)   { Document.joins(:tags) }
      let(:filters) { { name: 'test_name' } }

      let!(:first_tag) { Tag.find_or_create_by(name: 'ruby') }
      let!(:second_tag) { Tag.find_or_create_by(name: 'programming') }

      before do
        filters_class.filter_by :name
        document.tags << [first_tag, second_tag]
        other_document.tags << [first_tag]
      end

      it 'filters by document name, not tag name' do
        result = filter_instance.apply(scope)
        expect(result).to include(document)
      end

      it 'does not return documents that do not match document name' do
        result = filter_instance.apply(scope)
        expect(result).not_to include(other_document)
      end

      it 'generates SQL that includes documents table qualification for name field' do
        result = filter_instance.apply(scope)
        expect(result.to_sql).to include('"documents"."name"')
      end

      it 'generates SQL that includes the filter value' do
        result = filter_instance.apply(scope)
        expect(result.to_sql).to include("'test_name'")
      end

      context 'when using like filter' do
        let(:filters) { { name: 'test' } }

        before do
          filters_class.filter_by :name, match: :like
        end

        it 'filters by document name with LIKE operation' do
          result = filter_instance.apply(scope)
          expect(result).to include(document)
        end

        it 'does not return documents that do not match document name pattern' do
          result = filter_instance.apply(scope)
          expect(result).not_to include(other_document)
        end

        it 'generates SQL with table-qualified LIKE operation' do
          result = filter_instance.apply(scope)
          expect(result.to_sql).to include('documents.name LIKE')
        end

        it 'generates SQL with correct LIKE pattern' do
          result = filter_instance.apply(scope)
          expect(result.to_sql).to include("'%test%'")
        end
      end
    end
  end
end
