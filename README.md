# TerminalImage

[![Gem Version](https://badge.fury.io/rb/terminal_image.svg)](https://badge.fury.io/rb/terminal_image)
[![Circle CI](https://circleci.com/gh/unhappychoice/terminal_image.svg?style=shield)](https://circleci.com/gh/unhappychoice/terminal_image)
[![Code Climate](https://codeclimate.com/github/unhappychoice/terminal_image/badges/gpa.svg)](https://codeclimate.com/github/unhappychoice/terminal_image)
[![codecov](https://codecov.io/gh/unhappychoice/terminal_image/branch/master/graph/badge.svg)](https://codecov.io/gh/unhappychoice/terminal_image)
[![Libraries.io dependency status for GitHub repo](https://img.shields.io/librariesio/github/unhappychoice/terminal_image.svg)](https://libraries.io/github/unhappychoice/terminal_image)
![](http://ruby-gem-downloads-badge.herokuapp.com/terminal_image?type=total)
![GitHub](https://img.shields.io/github/license/unhappychoice/terminal_image.svg)

TerminalImage is a library to show images on terminals. 
Currently, this library supports [iTerm2](https://iterm2.com/index.html) and terminals with [libsixel](https://github.com/saitoha/libsixel) installed.

![](./images/example.png)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'terminal_image'
```

Terminals other than iTerm2:

Please install `libsixel`'s `img2sixel` command following https://github.com/saitoha/libsixel#install

## Usage

```ruby
# Print image by File object
TerminalImage.show(File.open('your-image-path.png'))

# Print image from URL
TerminalImage.show_url('https://raw.githubusercontent.com/unhappychoice/terminal_image/master/images/sample.png')

# Get encoded string ready to be displayed 
string = TerminalImage.encode(File.open('your-image-path.png'))

# Get encoded string ready to be displayed from URL
string = TerminalImage.encode_url('https://raw.githubusercontent.com/unhappychoice/terminal_image/master/images/sample.png')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/unhappychoice/terminal_image. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TerminalImage project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/unhappychoice/terminal_image/blob/master/CODE_OF_CONDUCT.md).
