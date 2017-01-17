require 'windows_gui'

include WindowsGUI

unless respond_to?(:MessageBoxTimeout)
	MessageBox(nil,
		L('MessageBoxTimeout is not supported'),
		nil,
		MB_ICONERROR
	); exit(-1)
end

MessageBoxTimeout(nil,
	L("Hello, world!\n\n(Disappearing in 3 seconds...)"),
	L('Hello'),
	MB_ICONINFORMATION,
	0,
	3000
)
