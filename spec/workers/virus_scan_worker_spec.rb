require 'rails_helper'

RSpec.describe VirusScanWorker do
  let(:worker) { described_class.new }
  let(:asset) { FactoryBot.create(:asset) }

  it "calls out to the VirusScanner to scan the file" do
    scanner = double("VirusScanner")
    expect(VirusScanner).to receive(:new).and_return(scanner)
    expect(scanner).to receive(:scan).with(asset.file.path).and_return(true)

    worker.perform(asset.id)
  end

  it "sets the state to clean if the file is clean" do
    allow_any_instance_of(VirusScanner).to receive(:scan).with(asset.file.path).and_return(true)

    worker.perform(asset.id)

    asset.reload
    expect(asset.state).to eq('clean')
  end

  context "when a virus is found" do
    let(:exception_message) { "/path/to/file: Eicar-Test-Signature FOUND" }
    let(:exception) { VirusScanner::InfectedFile.new(exception_message) }

    before do
      allow_any_instance_of(VirusScanner).to receive(:scan).with(asset.file.path)
        .and_raise(exception)
    end

    it "sets the state to infected if a virus is found" do
      worker.perform(asset.id)

      asset.reload
      expect(asset.state).to eq('infected')
    end

    it "sends an exception notification" do
      expect(GovukError).to receive(:notify).
        with(exception, extra: { id: asset.id, filename: asset.filename })

      worker.perform(asset.id)
    end
  end
end
