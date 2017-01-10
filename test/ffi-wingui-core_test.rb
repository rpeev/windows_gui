require_relative '../lib/ffi-wingui-core/common'
require 'minitest'
require 'minitest/autorun'

class WinGUITest < Minitest::Test
  def test_version
    refute_nil WinGUI::VERSION
  end
end
