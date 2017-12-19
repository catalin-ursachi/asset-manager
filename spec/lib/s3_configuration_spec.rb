require 'rails_helper'
require 's3_configuration'

RSpec.describe S3Configuration do
  subject(:config) { described_class.new(env) }

  let(:env) { {} }

  describe '.build' do
    subject(:config_class) { described_class }

    let(:production) { false }

    before do
      allow(Rails.env).to receive(:production?).and_return(production)
    end

    it 'returns instance of configuration' do
      expect(config_class.build).to be_instance_of(config_class)
    end

    context 'when Rails environment is production' do
      let(:production) { true }

      context 'when AWS_S3_BUCKET_NAME env var is not present' do
        it 'fails fast by raising an exception' do
          expect { config_class.build }.to raise_error(KeyError)
        end
      end
    end
  end

  describe '#bucket_name' do
    before do
      allow(Rails.env).to receive(:production?).and_return(production)
    end

    context 'when Rails environment is production' do
      let(:production) { true }

      context 'when AWS_S3_BUCKET_NAME env var is present' do
        let(:env) { { 'AWS_S3_BUCKET_NAME' => 's3-bucket-name' } }

        it 'returns S3 bucket name' do
          expect(config.bucket_name).to eq('s3-bucket-name')
        end
      end

      context 'when AWS_S3_BUCKET_NAME env var is not present' do
        it 'fails fast by raising an exception' do
          expect { config.bucket_name }.to raise_error(KeyError)
        end
      end
    end

    context 'when Rails environment is not production' do
      let(:production) { false }

      context 'when AWS_S3_BUCKET_NAME env var is present' do
        let(:env) { { 'AWS_S3_BUCKET_NAME' => 's3-bucket-name' } }

        it 'returns S3 bucket name' do
          expect(config.bucket_name).to eq('s3-bucket-name')
        end
      end

      context 'when AWS_S3_BUCKET_NAME env var is not present' do
        it 'returns nil and does not fail fast' do
          expect(config.bucket_name).to eq(nil)
        end
      end
    end
  end

  describe '#configured?' do
    context 'when bucket_name is set' do
      let(:env) { { 'AWS_S3_BUCKET_NAME' => 's3-bucket-name' } }

      it 'is considered to be configured' do
        expect(config).to be_configured
      end
    end

    context 'when bucket_name is not set' do
      it 'is considered not to be configured' do
        expect(config).not_to be_configured
      end
    end
  end

  describe '#fake?' do
    before do
      allow(Rails.env).to receive(:development?).and_return(development)
    end

    context 'when not configured' do
      context 'when Rails environment is development' do
        let(:development) { true }

        it 'is fake' do
          expect(config).to be_fake
        end
      end

      context 'when Rails environment is not development' do
        let(:development) { false }

        it 'is not fake' do
          expect(config).not_to be_fake
        end
      end
    end

    context 'when configured' do
      let(:env) { { 'AWS_S3_BUCKET_NAME' => 's3-bucket-name' } }

      context 'when Rails environment is development' do
        let(:development) { true }

        it 'is not fake' do
          expect(config).not_to be_fake
        end
      end

      context 'when Rails environment is not development' do
        let(:development) { false }

        it 'is not fake' do
          expect(config).not_to be_fake
        end
      end
    end
  end
end