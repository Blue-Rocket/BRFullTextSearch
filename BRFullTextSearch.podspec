Pod::Spec.new do |s|

  s.name         = "BRFullTextSearch"
  s.version      = "2.0.0"
  s.summary      = "Objective-C full text search engine."
  s.description  = <<-DESC
                   This project provides a way to integrate full-text search
                   capabilities into your iOS and OS X projects. First, it provides
                   a protocol-based API for a simple text indexing and search
                   framework. Second, it provides a
                   [CLucene](http://clucene.sourceforge.net/) based implementation of
                   that framework.
                   DESC

  s.homepage     = "https://github.com/Blue-Rocket/BRFullTextSearch"
  s.license      = "Apache License, Version 2.0"
  s.author       = { "Matt Magoffin" => "matt@bluerocket.us" }

  s.ios.deployment_target = '5.1'
  s.osx.deployment_target = '10.7'

  s.source       = { :git => "https://github.com/Blue-Rocket/BRFullTextSearch.git", :tag => s.version.to_s }

  s.libraries		= 'c++', 'z'
  s.compiler_flags	= '-fvisibility=default', '-fPIC', '-D_UCS2', '-D_UNICODE', '-D_REENTRANT',
  					  '-DNDEBUG'

  s.xcconfig		= {
  						'CLANG_CXX_LANGUAGE_STANDARD' => 'c++0x',
  						'CLANG_CXX_LIBRARY' => 'libc++',
  					  }

  s.requires_arc = true
  
  s.default_subspec = 'Core'

  s.subspec 'Core' do |as|
  	as.dependency 'BRFullTextSearch/API'
  	as.dependency 'BRFullTextSearch/Implementation-CLucene'
  end

  s.subspec 'API' do |as|
  	as.source_files = "BRFullTextSearch/*.{h,m}"
  	as.exclude_files = "BRFullTextSearch/*CLucene*",
  						"BRFullTextSearch/BRNoLockFactory.*",
  						"BRFullTextSearch/*Analyzer*",
  						"BRFullTextSearch/*Filter*"
  end

  s.subspec 'Implementation-CLucene' do |as|
  	as.source_files = "BRFullTextSearch/*CLucene*",
  						"BRFullTextSearch/BRNoLockFactory.*",
  						"BRFullTextSearch/*Analyzer*",
  						"BRFullTextSearch/*Filter*"
  	as.dependency 'BRFullTextSearch/API'
	as.dependency 'BRCLucene', '< 2.0'
  end

end
