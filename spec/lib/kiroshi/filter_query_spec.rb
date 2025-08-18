# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Kiroshi::FilterQuery, type: :model do
  describe '.for' do
    context 'when match is :exact' do
      it 'returns the Exact class' do
        expect(described_class.for(:exact)).to eq(Kiroshi::FilterQuery::Exact)
      end
    end

    context 'when match is :like' do
      it 'returns the Like class' do
        expect(described_class.for(:like)).to eq(Kiroshi::FilterQuery::Like)
      end
    end

    context 'when match is an unsupported type' do
      it 'raises ArgumentError for unsupported match type' do
        expect { described_class.for(:invalid) }.to raise_error(
          ArgumentError, 'Unsupported match type: invalid'
        )
      end

      it 'raises ArgumentError for nil match type' do
        expect { described_class.for(nil) }.to raise_error(
          ArgumentError, 'Unsupported match type: '
        )
      end

      it 'raises ArgumentError for string match type' do
        expect { described_class.for('exact') }.to raise_error(
          ArgumentError, 'Unsupported match type: exact'
        )
      end
    end
  end
end