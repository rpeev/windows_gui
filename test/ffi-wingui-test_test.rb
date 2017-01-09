#!/usr/bin/env ruby

require_relative '../lib/ffi-wingui-core/common'
require 'minitest/autorun'

class FooTest < Minitest::Test
  def test_version
    refute_nil WinGUI::VERSION
  end
end
