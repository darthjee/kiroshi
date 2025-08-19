# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::Filters::ClassMethods, type: :model do
  subject(:filters_class) { Class.new(Kiroshi::Filters) }

  let(:filter_instance) { filters_class.new(filters) }
  let(:scope)           { Document.all }
  let(:filters)         { {} }

  describe '.filter_by' do
    let(:scope)   { Document.all }
    let(:filters) { { name: name } }
    let(:name)    { 'test_name' }

    context 'when adding a new filter' do
      it do
        expect { filters_class.filter_by :name }
          .to change { filter_instance.apply(scope) }
          .from(scope).to(scope.where(name: name))
      end
    end

    context 'when adding a filter with table qualification' do
      let(:scope) { Document.joins(:tags) }

      it do
        expect { filters_class.filter_by :name, table: :documents }
          .to change { filter_instance.apply(scope) }
          .from(scope).to(scope.where(documents: { name: name }))
      end
    end

    context 'when adding a filter with different table' do
      let(:scope)   { Document.joins(:tags) }
      let(:filters) { { name: 'ruby' } }
      let(:name)    { 'ruby' }

      it do
        expect { filters_class.filter_by :name, table: :tags }
          .to change { filter_instance.apply(scope) }
          .from(scope).to(scope.where(tags: { name: name }))
      end
    end

    context 'when adding a like filter with table qualification' do
      let(:scope) { Document.joins(:tags) }
      let(:filters) { { name: 'test' } }
      let(:name)    { 'test' }

      it do
        expect { filters_class.filter_by :name, match: :like, table: :documents }
          .to change { filter_instance.apply(scope) }
          .from(scope).to(scope.where('`documents`.`name` LIKE ?', '%test%'))
      end
    end

    context 'when column is different from filter_key' do
      let(:filters) { { user_name: 'John Doe' } }

      context 'with exact match' do
        it do
          expect { filters_class.filter_by :user_name, column: :full_name }
            .to change { filter_instance.apply(scope) }
            .from(scope).to(scope.where(full_name: 'John Doe'))
        end
      end

      context 'with like match' do
        let(:filters) { { user_name: 'John' } }

        it do
          expect { filters_class.filter_by :user_name, match: :like, column: :full_name }
            .to change { filter_instance.apply(scope) }
            .from(scope).to(scope.where('`documents`.`full_name` LIKE ?', '%John%'))
        end
      end

      context 'with table qualification and different column' do
        let(:scope) { Document.joins(:tags) }
        let(:filters) { { tag_identifier: 'ruby' } }

        it do
          expect { filters_class.filter_by :tag_identifier, table: :tags, column: :name }
            .to change { filter_instance.apply(scope) }
            .from(scope).to(scope.where(tags: { name: 'ruby' }))
        end
      end

      context 'with like match, table qualification and different column' do
        let(:scope) { Document.joins(:tags) }
        let(:filters) { { tag_identifier: 'rub' } }

        it do
          expect { filters_class.filter_by :tag_identifier, match: :like, table: :tags, column: :name }
            .to change { filter_instance.apply(scope) }
            .from(scope).to(scope.where('`tags`.`name` LIKE ?', '%rub%'))
        end
      end
    end
  end
end
