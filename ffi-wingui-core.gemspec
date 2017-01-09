require_relative 'lib/ffi-wingui-core/common'
require 'rake'

Gem::Specification.new do |s|
  s.name = 'ffi-wingui-core'
  s.version = WinGUI::VERSION

  s.summary = 'Ruby-FFI (x86) bindings to essential GUI-related Windows APIs'
  s.description = 'Ruby-FFI (x86) bindings to essential GUI-related Windows APIs'
  s.homepage = 'https://github.com/rpeev/ffi-wingui-core'

  s.authors = ['Radoslav Peev']
  s.email = ['rpeev@ymail.com']
  s.licenses = ['MIT']

  s.files = FileList[
    'LICENSE',
    'README.md', 'screenshot.png',
    'RELNOTES.md',
    'lib/ffi-wingui-core.rb',
    'lib/ffi-wingui-core/*.rb',
    'examples/*.*', 'examples/res/*.*'
  ]
  s.require_paths = ['lib']
  s.add_runtime_dependency('ffi', '~> 1')
end
