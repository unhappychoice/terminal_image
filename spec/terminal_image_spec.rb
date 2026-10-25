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

      it 'does not call ImageMagick for PNG' do
        allow(Open3).to receive(:capture3)
        TerminalImage.encode(file)
        expect(Open3).not_to have_received(:capture3)
      end

      it 'raises for other formats when ImageMagick is not installed' do
        expect { TerminalImage.encode(File.open('spec/files/sample.gif')) }
          .to raise_error(TerminalImage::UnsupportedFormat, /Install ImageMagick to show gif images/)
      end

      it 'keeps UnsupportedFormat rescuable as UnsupportedTerminal' do
        expect(TerminalImage::UnsupportedFormat.ancestors).to include(TerminalImage::UnsupportedTerminal)
      end
    end

    context 'without iTerm2 and libsixel but with ImageMagick' do # rubocop:disable Metrics/BlockLength
      let(:gif) { File.open('spec/files/sample.gif') }
      let(:status) { instance_double(Process::Status, success?: true) }
      let(:png) { File.binread('spec/files/sample.png') }

      before { allow(ENV).to receive(:fetch) { 'Not a iTerm' } }
      before { allow(TerminalImage::AnsiEncoder).to receive(:terminal_width) { 30 } }
      before { allow(TerminalImage::PngConverter).to receive(:pipe) { [png, status] } }

      def stub_commands(*available, image_magick: available)
        allow(TerminalImage).to receive(:which) { |cmd| available.include?(cmd) ? "/usr/bin/#{cmd}" : nil }
        allow(TerminalImage::PngConverter).to receive(:image_magick?) { |cmd| image_magick.include?(cmd) }
      end

      it 'converts the first frame to PNG with magick' do
        stub_commands('magick', 'convert')
        expect(TerminalImage.encode(gif)).to eq(TerminalImage::AnsiEncoder.encode(File.open(file.path), width: 30))
        expect(TerminalImage::PngConverter).to have_received(:pipe)
          .with(['magick', *TerminalImage::PngConverter::RESOURCE_LIMITS, '-[0]', 'png:-'], gif)
      end

      it 'falls back to convert without magick' do
        stub_commands('convert')
        TerminalImage.encode(gif)
        expect(TerminalImage::PngConverter).to have_received(:pipe).with(['convert', *TerminalImage::PngConverter::RESOURCE_LIMITS, '-[0]', 'png:-'], gif)
      end

      it 'ignores a convert command that is not ImageMagick' do
        stub_commands('convert', image_magick: [])
        expect { TerminalImage.encode(gif) }.to raise_error(TerminalImage::UnsupportedFormat, /Install ImageMagick/)
        expect(TerminalImage::PngConverter).not_to have_received(:pipe)
      end

      it 'rejects oversized images before converting them' do
        stub_commands('magick')
        allow(FastImage).to receive(:size) { [10_000, 10_000] }
        expect { TerminalImage.encode(gif) }.to raise_error(TerminalImage::ImageTooLarge)
        expect(TerminalImage::PngConverter).not_to have_received(:pipe)
      end

      it 'raises when the conversion fails' do
        stub_commands('convert')
        allow(status).to receive(:success?) { false }
        expect { TerminalImage.encode(gif) }
          .to raise_error(TerminalImage::UnsupportedFormat, /convert could not convert the image/)
      end
    end
  end
end
