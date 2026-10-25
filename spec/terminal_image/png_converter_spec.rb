# frozen_string_literal: true

require 'terminal_image'

RSpec.describe TerminalImage::PngConverter do
  let(:command) { TerminalImage.send(:image_magick_command) }

  it 'converts a GIF to PNG with the installed ImageMagick' do
    skip 'ImageMagick is not installed' unless command

    png = described_class.convert(File.open('spec/files/sample.gif'), command: command)

    expect(FastImage.type(png)).to eq(:png)
    expect(FastImage.size(png)).to eq([150, 150])
  end

  describe '.image_magick?' do
    it 'accepts a command that reports ImageMagick' do
      allow(Open3).to receive(:capture2e) { ["Version: ImageMagick 7.1.1\n", instance_double(Process::Status, success?: true)] }
      expect(described_class.image_magick?('convert')).to be(true)
    end

    it 'rejects another program with the same name' do
      allow(Open3).to receive(:capture2e) { ['Invalid drive specification', instance_double(Process::Status, success?: false)] }
      expect(described_class.image_magick?('convert')).to be(false)
    end

    it 'rejects a command that cannot be run' do
      allow(Open3).to receive(:capture2e).and_raise(Errno::ENOENT)
      expect(described_class.image_magick?('convert')).to be(false)
    end
  end
end
