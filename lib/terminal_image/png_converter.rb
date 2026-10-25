# frozen_string_literal: true

require 'open3'
require 'stringio'

module TerminalImage
  # Converts images to PNG with the ImageMagick CLI, reading the first frame only.
  module PngConverter
    COMMANDS = %w[magick convert].freeze

    class << self
      def convert(file, command:)
        file.rewind
        png, _, status = Open3.capture3(command, '-[0]', 'png:-', stdin_data: file.read.b, binmode: true)
        raise UnsupportedFormat, "#{command} could not convert the image to PNG" unless status.success?

        StringIO.new(png)
      end
    end
  end
end
