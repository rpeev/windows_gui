require 'rake'

require_relative 'lib/windows_gui'

Gem::Specification.new do |spec|
  spec.name = 'windows_gui'
  spec.version = WINDOWS_GUI_VERSION

  spec.summary = 'Ruby FFI (x86) bindings to essential GUI related Windows APIs'
  spec.description = 'Ruby FFI (x86) bindings to essential GUI related Windows APIs'
  spec.homepage = 'https://github.com/rpeev/windows_gui'

  spec.authors = ['Radoslav Peev']
  spec.email = ['rpeev@ymail.com']
  spec.licenses = ['MIT']

  spec.files = FileList[
    'LICENSE',
    'README.md', 'screenshot.png',
    'RELNOTES.md',
    'lib/windows_gui.rb',
    'lib/windows_gui/*.rb',
    'examples/*.*', 'examples/res/*.*',
    'examples/UIRibbon/*.*'
  ]
  spec.require_paths = ['lib']
  spec.add_runtime_dependency('ffi', '~> 1')
end
