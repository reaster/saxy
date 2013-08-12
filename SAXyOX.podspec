Pod::Spec.new do |s|
  s.name     = 'SAXyOX'
  s.version  = '1.0.5'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'XML and JSON Binding Library'
  s.homepage = 'https://github.com/reaster/saxy'
  s.authors  = { 'Richard Easterling' => 'richard@OutsourceCafe.com' }
  s.source   = { :git => 'https://github.com/reaster/saxy.git', :tag => "#{s.version}" }
  s.source_files = 'SAXy/OX','SAXy/SAX','SAXy/JSON'
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  # s.ios.frameworks =

  s.osx.deployment_target = '10.7'
  # s.osx.frameworks =
end