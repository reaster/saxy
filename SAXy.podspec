Pod::Spec.new do |s|
  s.name     = 'SAXy OX'
  s.version  = '1.0.0'
  s.license  = 'Apache 2.0'
  s.summary  = 'XML and JSON Binding Library'
  s.homepage = 'https://github.com/reaster/saxy'
  s.authors  = { 'Richard Easterling' => 'richard@OutsourceCafe.com' }
  s.source   = { :git => 'https://github.com/reaster/saxy.git', :tag => '1.0.0' }
  s.source_files = 'SAXy'
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.ios.frameworks =

  s.osx.deployment_target = '10.7'
  s.osx.frameworks =
end