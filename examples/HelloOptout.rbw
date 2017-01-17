WINDOWS_GUI_VISUAL_STYLES = false
WINDOWS_GUI_DPI_AWARE = false

require 'windows_gui'

include WindowsGUI

MessageBox(nil,
	L('Hello, world!'),
	L('Hello'),
	MB_ICONINFORMATION
)
