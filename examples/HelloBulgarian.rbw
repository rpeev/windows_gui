# encoding: UTF-8

require 'windows_gui'

include WindowsGUI

MessageBox(nil,
	L('Здрасти, свят!'),
	L('Здрасти'),
	MB_ICONINFORMATION
)
