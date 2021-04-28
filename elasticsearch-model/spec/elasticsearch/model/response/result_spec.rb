# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'
require 'active_support/json/encoding'

describe Elasticsearch::Model::Response::Result do

  let(:result) do
    described_class.new(foo: 'bar', bar: { bam: 'baz' })
  end

  it 'provides access to the properties' do
    expect(result.foo).to eq('bar')
    expect(result.bar.bam).to eq('baz')
    expect { result.xoxo }.to raise_exception(NoMethodError)
  end

  describe '#id' do

    let(:result) do
      described_class.new(foo: 'bar', _id: 42, _source: { id: 12 })
    end

    it 'returns the _id field' do
      expect(result.id).to eq(42)
    end

    it 'provides access to the source id field' do
      expect(result._source.id).to eq(12)
    end
  end

  describe '#type' do

    let(:result) do
      described_class.new(foo: 'bar', _type: 'baz', _source: { type: 'BAM' })
    end

    it 'returns the _type field' do
      expect(result.type).to eq('baz')
    end

    it 'provides access to the source type field' do
      expect(result._source.type).to eq('BAM')
    end
  end

  describe 'method delegation' do

    let(:result) do
      described_class.new(foo: 'bar', _source: { bar: { bam: 'baz' } })
    end

    it 'provides access to the _source field via a method' do
      expect(result._source).to eq('bar' => { 'bam' => 'baz' })
    end

    it 'is recognized by #method' do
      expect(result.method :bar).to be_a Method
    end

    it 'respond_to? still works' do
      expect(result.respond_to? :bar).to be true
    end

    context 'when methods map to keys in subdocuments of the response from Elasticsearch' do

      it 'provides access to top level fields via a method' do
        expect(result.foo).to eq('bar')
        expect(result.fetch(:foo)).to eq('bar')
        expect(result.fetch(:does_not_exist, 'moo')).to eq('moo')
      end

      it 'responds to hash methods' do
        expect(result.keys).to eq(['foo', '_source'])
        expect(result.to_hash).to eq('foo' => 'bar', '_source' => { 'bar' => { 'bam' => 'baz' } })
      end

      it 'provides access to fields in the _source subdocument via a method' do
        expect(result.bar).to eq('bam' => 'baz')
        expect(result.bar.bam).to eq('baz')
        expect(result._source.bar).to eq('bam' => 'baz')
        expect(result._source.bar.bam).to eq('baz')
      end

      context 'when boolean methods are called' do

        it 'provides access to top level fields via a method' do
          expect(result.foo?).to eq(true)
          expect(result.boo?).to eq(false)
        end

        it 'delegates to fields in the _source subdocument via a method' do
          expect(result.bar?).to eq(true)
          expect(result.bar.bam?).to eq(true)
          expect(result.boo?).to eq(false)
          expect(result.bar.boo?).to eq(false)
          expect(result._source.bar?).to eq(true)
          expect(result._source.bar.bam?).to eq(true)
          expect(result._source.boo?).to eq(false)
          expect(result._source.bar.boo?).to eq(false)
        end
      end
    end

    context 'when methods do not map to keys in subdocuments of the response from Elasticsearch' do

      it 'raises a NoMethodError' do
        expect { result.does_not_exist }.to raise_exception(NoMethodError)
      end
    end
  end

  describe '#as_json' do

    let(:result) do
      described_class.new(foo: 'bar', _source: { bar: { bam: 'baz' } })
    end

    it 'returns a json string' do
      expect(result.as_json(except: 'foo')).to eq({'_source'=>{'bar'=>{'bam'=>'baz'}}})
    end
  end
end
