#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zwj_scan_plugin.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'zwj_scan_plugin'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter scan plugin.'
  s.description      = <<-DESC
A new Flutter scan plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  #图片资源处理
  s.resources = ['Classes/*.png']

  s.dependency 'Flutter'
  s.dependency 'ScanKitFrameWork', '~> 1.0.2.300'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
