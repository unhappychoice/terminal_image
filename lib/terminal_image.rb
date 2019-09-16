require "terminal_image/version"
require 'fastimage'

module TerminalImage
  class UnsupportedTerminal < StandardError; end

  class << self
    def show(file)
      if ENV['TERM_PROGRAM'] == 'iTerm.app'
        show_on_iterm2(file)
      else
        raise UnsupportedTerminal, 'Unsupported terminal'
      end
    end

    private

    def show_on_iterm2(file)
      width, height = FastImage.size(file)
      print "\033]1337;File=inline=1;width=#{width}px;height=#{height}px:"
      print Base64.strict_encode64(file.read)
      print "\a\n"
    end
  end
end
