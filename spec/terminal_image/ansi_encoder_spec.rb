# frozen_string_literal: true

require 'stringio'
require 'terminal_image'

RSpec.describe TerminalImage::AnsiEncoder do # rubocop:disable Metrics/BlockLength
  let(:red) { ChunkyPNG::Color.rgb(255, 0, 0) }
  let(:blue) { ChunkyPNG::Color.rgb(0, 0, 255) }
  let(:transparent) { ChunkyPNG::Color::TRANSPARENT }

  def png(rows)
    image = ChunkyPNG::Image.new(rows.first.size, rows.size)
    rows.each_with_index { |row, y| row.each_with_index { |color, x| image[x, y] = color } }
    StringIO.new(image.to_blob)
  end

  def fg(red, green, blue) = "\e[38;2;#{red};#{green};#{blue}m"

  def bg(red, green, blue) = "\e[48;2;#{red};#{green};#{blue}m"

  describe '.encode' do # rubocop:disable Metrics/BlockLength
    it 'draws two pixel rows per cell with an upper half block' do
      expect(described_class.encode(png([[red], [blue]]), width: 80))
        .to eq("#{fg(255, 0, 0)}#{bg(0, 0, 255)}▀\e[0m")
    end

    it 'keeps the default background below the last row of an odd-height image' do
      expect(described_class.encode(png([[red]]), width: 80)).to eq("#{fg(255, 0, 0)}\e[49m▀\e[0m")
    end

    it 'uses a lower half block when only the bottom pixel is visible' do
      expect(described_class.encode(png([[transparent], [blue]]), width: 80)).to eq("#{fg(0, 0, 255)}\e[49m▄\e[0m")
    end

    it 'prints a blank cell when both pixels are transparent' do
      expect(described_class.encode(png([[transparent], [transparent]]), width: 80)).to eq("\e[49m \e[0m")
    end

    it 'separates cell rows with newlines' do
      expect(described_class.encode(png([[red], [red], [blue], [blue]]), width: 80))
        .to eq("#{fg(255, 0, 0)}#{bg(255, 0, 0)}▀\e[0m\n#{fg(0, 0, 255)}#{bg(0, 0, 255)}▀\e[0m")
    end

    it 'scales wide images down to the given width, keeping the aspect ratio' do
      lines = described_class.encode(File.open('spec/files/sample.png'), width: 30).lines

      expect(lines.size).to eq(15)
      expect(lines.map { |line| line.scan(/[▀▄ ]/).size }).to all(eq(30))
    end

    it 'does not scale images up' do
      lines = described_class.encode(png([[red, blue], [blue, red]]), width: 80).lines

      expect(lines.first.scan('▀').size).to eq(2)
    end

    it 'reads the file from the beginning' do
      file = png([[red]])
      file.read

      expect(described_class.encode(file, width: 80)).to include(fg(255, 0, 0))
    end
  end

  describe '.terminal_width' do
    it 'uses the console width' do
      allow(IO).to receive(:console).and_return(instance_double(IO, winsize: [24, 100]))

      expect(described_class.terminal_width).to eq(100)
    end

    it 'falls back to COLUMNS without a console' do
      allow(IO).to receive(:console).and_return(nil)
      allow(ENV).to receive(:fetch).with('COLUMNS', nil).and_return('42')

      expect(described_class.terminal_width).to eq(42)
    end

    it 'falls back to 80 columns when nothing is known' do
      allow(IO).to receive(:console).and_return(nil)
      allow(ENV).to receive(:fetch).with('COLUMNS', nil).and_return(nil)

      expect(described_class.terminal_width).to eq(80)
    end
  end
end
