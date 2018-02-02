require 'rails_helper'
require 'services'

RSpec.describe VirusScanWorker do
  let(:worker) { described_class.new }
  let(:asset) { FactoryBot.create(:asset) }
  let(:scanner) { instance_double('VirusScanner') }

  before do
    allow(Services).to receive(:virus_scanner).and_return(scanner)
  end

  it "calls out to the VirusScanner to scan the file" do
    expect(scanner).to receive(:scan).with(asset.file.path)

    worker.perform(asset.id)
  end

  context 'when the file is clean' do
    before do
      allow(scanner).to receive(:scan).and_return(true)
    end

    it "sets the state to clean" do
      worker.perform(asset.id)

      asset.reload
      expect(asset).to be_clean
    end
  end

  context "when a virus is found" do
    let(:exception_message) { "/path/to/file: Eicar-Test-Signature FOUND" }
    let(:exception) { VirusScanner::InfectedFile.new(exception_message) }

    before do
      allow(scanner).to receive(:scan).and_raise(exception)
    end

    it "sets the state to infected if a virus is found" do
      worker.perform(asset.id)

      asset.reload
      expect(asset).to be_infected
    end

    it "sends an exception notification" do
      expect(GovukError).to receive(:notify).
        with(exception, extra: { id: asset.id, filename: asset.filename })

      worker.perform(asset.id)
    end
  end
end
