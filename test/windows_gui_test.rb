require 'minitest'
require 'minitest/autorun'

require_relative '../lib/windows_gui'

include WindowsGUI

class WindowsGUITest < Minitest::Test
  def test_WINDOWS_GUI_xxx
    assert_match %r{^\d+\.\d+\.\d+(\.\d+)?$}, WINDOWS_GUI_VERSION
    assert WINDOWS_GUI_VISUAL_STYLES
    assert WINDOWS_GUI_DPI_AWARE
  end

  def test_FormatException
    boom
  rescue => ex
    assert_match %r{\n\n-- backtrace --\n\n}, FormatException(ex)
  end

  def test_Id2RefTrack
    obj = Object.new
    oid = Id2RefTrack(obj)

    assert Id2Ref[oid] == obj
  end

  def test_UsingFFIStructs
    UsingFFIStructs(POINT.new, POINT.new) { |pt1, pt2|

    }
  end

  def test_UsingFFIMemoryPointers
    UsingFFIMemoryPointers(PWSTR(L('foo')), PWSTR(L('bar'))) { |ptr1, ptr2|

    }
  end
end
