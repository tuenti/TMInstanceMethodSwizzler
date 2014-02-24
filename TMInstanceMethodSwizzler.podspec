Pod::Spec.new do |s|
  s.name         = 'TMInstanceMethodSwizzler'
  s.version      = '0.1.0'
  s.homepage     = 'https://github.com/tuenti/TMInstanceMethodSwizzler'
  s.summary      = 'Class which allows you to swizzle methods from object instances (not your regular class method swizzling)'
  s.authors      = { 'Tuenti Technologies S.L.' => 'https://twitter.com/TuentiEng' }
  s.source       = { :git => 'https://github.com/tuenti/TMInstanceMethodSwizzler.git', :tag => s.version.to_s }
  s.source_files = 'Classes/*.{h,m}'
  s.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.requires_arc = true
end
