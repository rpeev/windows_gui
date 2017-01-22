require 'windows_gui'

include WindowsGUI

MessageBox(nil,
	L("Ruby #{RUBY_VERSION} on #{WINNAME}"),
	APPNAME,
	MB_ICONINFORMATION
)
