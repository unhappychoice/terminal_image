# frozen_string_literal: true

require 'terminal_image'

RSpec.describe TerminalImage::PngConverter do
  let(:command) { described_class::COMMANDS.find { |cmd| TerminalImage.send(:which, cmd) } }

  it 'converts a GIF to PNG with the installed ImageMagick' do
    skip 'ImageMagick is not installed' unless command

    png = described_class.convert(File.open('spec/files/sample.gif'), command: command)

    expect(FastImage.type(png)).to eq(:png)
    expect(FastImage.size(png)).to eq([150, 150])
  end
end
