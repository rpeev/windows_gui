require 'rake'

require_relative 'lib/windows_gui/common'

Gem::Specification.new do |s|
  s.name = 'windows_gui'
  s.version = WindowsGUI::VERSION

  s.summary = 'Ruby FFI (x86) bindings to essential GUI related Windows APIs'
  s.description = 'Ruby FFI (x86) bindings to essential GUI related Windows APIs'
  s.homepage = 'https://github.com/rpeev/windows_gui'

  s.authors = ['Radoslav Peev']
  s.email = ['rpeev@ymail.com']
  s.licenses = ['MIT']

  s.files = FileList[
    'LICENSE',
    'README.md', 'screenshot.png',
    'RELNOTES.md',
    'lib/windows_gui.rb',
    'lib/windows_gui/*.rb',
    'examples/*.*', 'examples/res/*.*'
  ]
  s.require_paths = ['lib']
  s.add_runtime_dependency('ffi', '~> 1')
end
