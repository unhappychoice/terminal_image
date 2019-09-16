# frozen_string_literal: true

require 'terminal_image'

RSpec.describe TerminalImage do # rubocop:disable Metrics/BlockLength
  it 'has a version number' do
    expect(TerminalImage::VERSION).not_to be nil
  end

  shared_context 'with mocked tempfile' do
    let(:tempfile) { double('tempfile') }

    before do
      allow(Tempfile).to receive(:create) { tempfile }
      allow(tempfile).to receive(:binmode)
      allow(tempfile).to receive(:path) { File.open('spec/files/sample.png').path }
      allow(tempfile).to receive(:read) { File.read('spec/files/sample.png') }
      allow(URI).to receive(:open)
    end
  end

  describe '#show_url' do
    include_context 'with mocked tempfile'

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a\n" }
      before { allow(ENV).to receive(:[]) { 'iTerm.app' } }
      it { expect { TerminalImage.show_url('http://example.com/sample.png') }.to output(expected).to_stdout }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\\n" }
      before do
        allow(ENV).to receive(:[]) { 'Not a iTerm' }
        allow(TerminalImage).to receive(:which) { true }
      end
      it { expect { TerminalImage.show_url('http://example.com/sample.png') }.to output(expected).to_stdout }
    end
  end

  describe '#show' do
    let(:file) { File.open('spec/files/sample.png') }

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a\n" }
      before { allow(ENV).to receive(:[]) { 'iTerm.app' } }
      it { expect { TerminalImage.show(file) }.to output(expected).to_stdout }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\\n" }
      before do
        allow(ENV).to receive(:[]) { 'Not a iTerm' }
        allow(TerminalImage).to receive(:which) { true }
      end
      it { expect { TerminalImage.show(file) }.to output(expected).to_stdout }
    end
  end

  describe '#encode_url' do
    include_context 'with mocked tempfile'

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a" }
      before { allow(ENV).to receive(:[]) { 'iTerm.app' } }
      it { expect(TerminalImage.encode_url('http://example.com/sample.png')).to eq(expected) }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\" }
      before { allow(ENV).to receive(:[]) { 'Not a iTerm' } }
      before { allow(TerminalImage).to receive(:which) { true } }
      it { expect(TerminalImage.encode_url('http://example.com/sample.png')).to eq(expected) }
    end
  end

  describe '#encode' do
    let(:file) { File.open('spec/files/sample.png') }

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a" }
      before { allow(ENV).to receive(:[]) { 'iTerm.app' } }
      it { expect(TerminalImage.encode(file)).to eq(expected) }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\" }
      before { allow(ENV).to receive(:[]) { 'Not a iTerm' } }
      before { allow(TerminalImage).to receive(:which) { true } }
      it { expect(TerminalImage.encode(file)).to eq(expected) }
    end

    context 'with unsupported terminal' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\" }
      before { allow(ENV).to receive(:[]) { 'Not a iTerm' } }
      before { allow(TerminalImage).to receive(:which) { false } }
      it { expect { TerminalImage.encode(file) }.to raise_error(TerminalImage::UnsupportedTerminal) }
    end
  end
end
