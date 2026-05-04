Pod::Spec.new do |s|
  s.name             = 'bclibc_ffi'
  s.version          = '0.0.1'
  s.summary          = 'Ballistics engine (bclibc) C++ FFI wrapper for Flutter.'
  s.homepage         = 'https://github.com/o-murphy/ebalistyka-app'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'o-murphy' => '' }

  # bclibc C++ sources are compiled directly from the git submodule.
  # Ensure `git submodule update --init --recursive` has been run first.
  s.source       = { :path => '.' }
  s.source_files = [
    '../../external/bclibc/src/**/*.{cpp}',
    '../../external/bclibc/include/**/*.{hpp,h}',
  ]

  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE'              => 'YES',
    'HEADER_SEARCH_PATHS'         => '"$(PODS_TARGET_SRCROOT)/../../external/bclibc/include"',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY'           => 'libc++',
    'OTHER_CPLUSPLUSFLAGS'        => '-O3 -ffast-math',
  }
end
