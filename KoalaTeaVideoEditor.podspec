#
# Be sure to run `pod lib lint KoalaTeaVideoEditor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KoalaTeaVideoEditor'
  s.version          = '0.1.0'
  s.summary          = 'A library to help with video editing'
  s.homepage         = 'https://github.com/themisterholliday/KoalaTeaVideoEditor'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Craig Holliday' => 'hello@craigholliday.net' }
  s.source           = { :git => 'https://github.com/themisterholliday/KoalaTeaVideoEditor.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/TheMrHolliday'

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files = 'KoalaTeaVideoEditor/Classes/**/*'
  s.resources = ['KoalaTeaVideoEditor/Assets/**/*']

  s.dependency 'SwifterSwift', '~> 5.0.0'
  s.dependency 'SwiftLint', '~> 0.33.0'
  s.dependency 'KoalaTeaAutoLayout', '~> 0.1.0'
  s.dependency 'KoalaTeaAssetPlayer', '~> 0.2.1'
end
