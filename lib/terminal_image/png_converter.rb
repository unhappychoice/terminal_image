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
        png, status = pipe([command, *RESOURCE_LIMITS, '-[0]', 'png:-'], file)
        raise UnsupportedFormat, "#{command} could not convert the image to PNG" unless status.success?

        StringIO.new(png)
      end

      def image_magick?(command)
        output, status = Open3.capture2e(command, '-version')
        status.success? && output.include?('ImageMagick')
      rescue SystemCallError
        false
      end

      private

      def pipe(args, input)
        Open3.popen2(*args, err: File::NULL) do |stdin, stdout, wait|
          [stdin, stdout].each(&:binmode)
          writer = Thread.new { stream(input, stdin) }
          png = stdout.read
          writer.join
          [png, wait.value]
        end
      end

      def stream(input, stdin)
        IO.copy_stream(input, stdin)
      rescue Errno::EPIPE
        nil
      ensure
        stdin.close
      end
    end
  end
end
