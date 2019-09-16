# frozen_string_literal: true

require 'terminal_image/version'
require 'fastimage'
require 'open-uri'
require 'tempfile'

module TerminalImage
  class UnsupportedTerminal < StandardError; end

  class << self
    def show_url(url)
      tempfile = Tempfile.create
      tempfile.binmode
      URI.open(url) { |o| tempfile.write o.read }
      TerminalImage.show(tempfile)
    end

    def show(file)
      puts encode(file)
    end

    def encode_url(url)
      tempfile = Tempfile.create
      tempfile.binmode
      URI.open(url) { |o| tempfile.write o.read }
      TerminalImage.encode(tempfile)
    end

    def encode(file)
      if ENV['TERM_PROGRAM'] == 'iTerm.app'
        encode_for_iterm2(file)
      elsif which 'img2sixel'
        encode_for_libsixel(file)
      else
        puts 'Use iTerm2 or install libsixel according to https://github.com/saitoha/libsixel#install'
        raise UnsupportedTerminal, 'Unsupported terminal'
      end
    end

    private

    def encode_for_iterm2(file)
      width, height = FastImage.size(file)
      "\033]1337;File=inline=1;width=#{width}px;height=#{height}px:#{Base64.strict_encode64(file.read)}\a\n"
    end

    def encode_for_libsixel(file)
      `img2sixel < #{file.path} 2>/dev/null`
    end

    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable?(exe) && !File.directory?(exe)
        end
      end
      nil
    end
  end
end
