WINGUI_VISUAL_STYLES = false
WINGUI_DPI_AWARE = false

require 'ffi-wingui-core'

include WinGUI

MessageBox(nil,
	L('Hello, world!'),
	L('Hello'),
	MB_ICONINFORMATION
)
