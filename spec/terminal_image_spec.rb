# frozen_string_literal: true

RSpec.describe TerminalImage do
  it 'has a version number' do
    expect(TerminalImage::VERSION).not_to be nil
  end
end
