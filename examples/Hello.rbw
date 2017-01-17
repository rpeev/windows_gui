require 'windows_gui'

include WindowsGUI

MessageBox(nil,
	L('Hello, world!'),
	L('Hello'),
	MB_ICONINFORMATION
)
