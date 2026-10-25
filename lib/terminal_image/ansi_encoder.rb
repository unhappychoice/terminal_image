# frozen_string_literal: true

require 'chunky_png'
require 'io/console'

module TerminalImage
  # Renders a PNG with 24-bit ANSI colors, two pixel rows per character cell.
  module AnsiEncoder
    UPPER_HALF_BLOCK = '▀'
    LOWER_HALF_BLOCK = '▄'
    DEFAULT_BACKGROUND = "\e[49m"
    RESET = "\e[0m"
    DEFAULT_WIDTH = 80
    MIN_VISIBLE_ALPHA = 128

    class << self
      def encode(file, width: terminal_width)
        file.rewind
        image = fit_to_width(ChunkyPNG::Image.from_io(file), width)
        row_pairs(image).map { |top, bottom| encode_line(top, bottom) }.join("\n")
      end

      def terminal_width
        [console_width, ENV.fetch('COLUMNS', nil).to_i].compact.find(&:positive?) || DEFAULT_WIDTH
      end

      private

      def console_width
        IO.console&.winsize&.last
      rescue SystemCallError
        nil
      end

      def fit_to_width(image, width)
        return image if image.width <= width

        height = [(image.height * width / image.width.to_f).round, 1].max
        image.resample_nearest_neighbor(width, height)
      end

      def row_pairs(image)
        (0...image.height).step(2).map do |y|
          [image.row(y), y + 1 < image.height ? image.row(y + 1) : []]
        end
      end

      def encode_line(top, bottom)
        top.each_with_index.map { |color, x| encode_cell(color, bottom[x]) }.join + RESET
      end

      def encode_cell(top, bottom)
        case [visible?(top), visible?(bottom)]
        when [true, true] then "#{foreground(top)}#{background(bottom)}#{UPPER_HALF_BLOCK}"
        when [true, false] then "#{foreground(top)}#{DEFAULT_BACKGROUND}#{UPPER_HALF_BLOCK}"
        when [false, true] then "#{foreground(bottom)}#{DEFAULT_BACKGROUND}#{LOWER_HALF_BLOCK}"
        else "#{DEFAULT_BACKGROUND} "
        end
      end

      def visible?(color)
        !color.nil? && ChunkyPNG::Color.a(color) >= MIN_VISIBLE_ALPHA
      end

      def foreground(color)
        "\e[38;2;#{rgb(color)}m"
      end

      def background(color)
        "\e[48;2;#{rgb(color)}m"
      end

      def rgb(color)
        ChunkyPNG::Color.to_truecolor_bytes(color).join(';')
      end
    end
  end
end
