# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeServer::TZMap do
  describe '.times_by_ids' do
    context 'available keys' do
      let(:keys) { TZInfo::Timezone.all.first(2).map { |i| i.name.sub(%r{.*/(.+)$}, '\1') } }

      it 'returns hash with 3 instances' do
        expect(described_class.times_by_ids(keys).size).to be_eql 3
      end
    end

    context 'giving no arguments' do
      it 'returns hash with 1 instance (UTC time)' do
        expect(described_class.times_by_ids.size).to be_eql 1
      end
    end

    context 'some random keys' do
      let(:keys) { %w[NonExistent RandomCities] }
      it 'returns hash with 1 instance (UTC time)' do
        expect(described_class.times_by_ids.size).to be_eql 1
      end
    end
  end
end
