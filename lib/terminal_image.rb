require "terminal_image/version"
require 'fastimage'

module TerminalImage
  class UnsupportedTerminal < StandardError; end

  class << self
    def show(file)
      if ENV['TERM_PROGRAM'] == 'iTerm.app'
        show_on_iterm2(file)
      elsif which 'img2sixel'
        show_by_libsixel(file)
      else
        raise UnsupportedTerminal, 'Unsupported terminal'
      end
    end

    private

    def show_by_libsixel(file)
      print `img2sixel < #{file.path} 2>/dev/null`
    end

    def show_on_iterm2(file)
      width, height = FastImage.size(file)
      print "\033]1337;File=inline=1;width=#{width}px;height=#{height}px:"
      print Base64.strict_encode64(file.read)
      print "\a\n"
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
