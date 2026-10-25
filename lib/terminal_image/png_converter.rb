# frozen_string_literal: true

require 'open3'
require 'stringio'

module TerminalImage
  # Converts images to PNG with the ImageMagick CLI, reading the first frame only.
  module PngConverter
    COMMANDS = %w[magick convert].freeze
    RESOURCE_LIMITS = %w[-limit memory 256MiB -limit disk 1GiB].freeze

    class << self
      def convert(file, command:)
        file.rewind
        args = [command, *RESOURCE_LIMITS, '-[0]', 'png:-']
        png, _, status = Open3.capture3(*args, stdin_data: file.read.b, binmode: true)
        raise UnsupportedFormat, "#{command} could not convert the image to PNG" unless status.success?

        StringIO.new(png)
      end

      def image_magick?(command)
        output, status = Open3.capture2e(command, '-version')
        status.success? && output.include?('ImageMagick')
      rescue SystemCallError
        false
      end
    end
  end
end
