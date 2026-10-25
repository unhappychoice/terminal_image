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
      allow(URI).to receive_message_chain(:parse, :open)
    end
  end

  describe '#show_url' do
    include_context 'with mocked tempfile'

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a\n" }
      before { allow(ENV).to receive(:fetch) { 'iTerm.app' } }
      it { expect { TerminalImage.show_url('http://example.com/sample.png') }.to output(expected).to_stdout }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\\n" }
      before do
        allow(ENV).to receive(:fetch) { 'Not a iTerm' }
        allow(TerminalImage).to receive(:which) { true }
      end
      it { expect { TerminalImage.show_url('http://example.com/sample.png') }.to output(expected).to_stdout }
    end
  end

  describe '#show' do
    let(:file) { File.open('spec/files/sample.png') }

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a\n" }
      before { allow(ENV).to receive(:fetch) { 'iTerm.app' } }
      it { expect { TerminalImage.show(file) }.to output(expected).to_stdout }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\\n" }
      before do
        allow(ENV).to receive(:fetch) { 'Not a iTerm' }
        allow(TerminalImage).to receive(:which) { true }
      end
      it { expect { TerminalImage.show(file) }.to output(expected).to_stdout }
    end
  end

  describe '#encode_url' do
    include_context 'with mocked tempfile'

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a" }
      before { allow(ENV).to receive(:fetch) { 'iTerm.app' } }
      it { expect(TerminalImage.encode_url('http://example.com/sample.png')).to eq(expected) }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\" }
      before { allow(ENV).to receive(:fetch) { 'Not a iTerm' } }
      before { allow(TerminalImage).to receive(:which) { true } }
      it { expect(TerminalImage.encode_url('http://example.com/sample.png')).to eq(expected) }
    end
  end

  describe '#encode' do # rubocop:disable Metrics/BlockLength
    let(:file) { File.open('spec/files/sample.png') }

    context 'with iTerm2' do
      let(:expected) { "\e]1337;#{File.read('spec/files/sample_encoded_iterm')}\a" }
      before { allow(ENV).to receive(:fetch) { 'iTerm.app' } }
      it { expect(TerminalImage.encode(file)).to eq(expected) }
    end

    context 'with sixel' do
      let(:expected) { "\eP#{File.read('spec/files/sample_encoded_sixel')}\e\\" }
      before { allow(ENV).to receive(:fetch) { 'Not a iTerm' } }
      before { allow(TerminalImage).to receive(:which) { true } }
      it { expect(TerminalImage.encode(file)).to eq(expected) }
    end

    context 'without iTerm2 and libsixel' do
      before { allow(ENV).to receive(:fetch) { 'Not a iTerm' } }
      before { allow(TerminalImage).to receive(:which) { false } }
      before { allow(TerminalImage::AnsiEncoder).to receive(:terminal_width) { 30 } }

      it 'falls back to ANSI colors' do
        expect(TerminalImage.encode(file)).to eq(TerminalImage::AnsiEncoder.encode(File.open(file.path), width: 30))
      end

      it 'raises for formats other than PNG' do
        gif = StringIO.new("GIF89a\x01\x00\x01\x00\x00\x00\x00;".b)
        expect { TerminalImage.encode(gif) }.to raise_error(TerminalImage::UnsupportedFormat, /got gif/)
      end

      it 'keeps UnsupportedFormat rescuable as UnsupportedTerminal' do
        expect(TerminalImage::UnsupportedFormat.ancestors).to include(TerminalImage::UnsupportedTerminal)
      end
    end
  end
end
