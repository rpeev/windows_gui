require 'windows_gui'

include WindowsGUI

MessageBox(nil,
	L("WindowsGUI #{WINDOWS_GUI_VERSION}\n\nRuby #{RUBY_VERSION} on #{WINNAME}"),
	APPNAME,
	MB_ICONINFORMATION
)
