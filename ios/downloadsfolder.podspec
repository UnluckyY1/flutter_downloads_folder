#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint downloadsfolder.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'downloadsfolder'
  s.version          = '2.0.0-pre.2'
  s.summary          = 'Retrieve and operate on the platform downloads folder.'
  s.description      = <<-DESC
A Flutter plugin for retrieving the path to the downloads folder and performing
operations related to file downloads on different platforms.
                       DESC
  s.homepage         = 'https://github.com/UnluckyY1/flutter_downloads_folder'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'UnluckyY1' => 'noreply@github.com' }
  s.source           = { :path => '.' }
  s.source_files = 'downloadsfolder/Sources/downloadsfolder/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
