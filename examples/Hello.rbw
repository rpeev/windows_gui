require 'ffi-wingui-core'

include WinGUI

MessageBox(nil,
	L('Hello, world!'),
	L('Hello'),
	MB_ICONINFORMATION
)
