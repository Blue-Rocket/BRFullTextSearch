Pod::Spec.new do |s|

  s.name         = "BRFullTextSearch"
  s.version      = "1.1.1"
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

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'

  s.source       = { :git => "https://github.com/Blue-Rocket/BRFullTextSearch.git",
  					 :tag => s.version.to_s, :submodules => true }

  s.libraries		= 'stdc++', 'z'
  s.compiler_flags	= '-Wmost',
  					  '-fvisibility=default', '-fPIC', '-D_UCS2', '-D_UNICODE', '-D_REENTRANT',
  					  '-DNDEBUG'

  s.xcconfig		= {
  						'CLANG_CXX_LANGUAGE_STANDARD' => 'gnu++98',
  						'CLANG_CXX_LIBRARY' => 'libstdc++',
  						'OTHER_LDFLAGS' => '-stdlib=libstdc++',
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
	as.dependency 'BRFullTextSearch/CLucene'
  end

  s.subspec 'CLucene' do |as|
  	as.dependency 'BRFullTextSearch/CLucene-Shared'
 	as.dependency 'BRFullTextSearch/CLucene-Core'
 	as.dependency 'BRFullTextSearch/CLucene-Contribs-Lib'
  end

  s.subspec 'CLucene-Config' do |as|
  	as.requires_arc = false
  	as.source_files = "BRFullTextSearch/CLucene/*"
  	as.header_mappings_dir = 'BRFullTextSearch'
  end

  s.subspec 'CLucene-Core-API' do |as|
  	as.requires_arc = false
  	as.source_files = "clucene/src/core/CLucene.h",
  	                  "clucene/src/core/CLucene/**/*.h"
  	as.header_mappings_dir = 'clucene/src/core'
  	as.exclude_files = "clucene/src/core/CLucene/CLMonolithic.*",
						"clucene/src/core/CLucene/search/FilterResultCache.*",
						"clucene/src/core/CLucene/queryParser/legacy"
    as.dependency 'BRFullTextSearch/CLucene-Config'
  end

  s.subspec 'CLucene-Shared' do |as|
  	as.requires_arc = false
  	as.source_files = "clucene/src/shared/CLucene/**/*.{h,c,cpp}"
  	as.header_mappings_dir = 'clucene/src/shared'
  	as.exclude_files = "clucene/src/shared/CLucene/CLSharedMonolithic.*",
                    	"clucene/src/shared/CLucene/util/deflate.*"
    as.dependency 'BRFullTextSearch/CLucene-Core-API'
  end

  s.subspec 'CLucene-Core' do |as|
  	as.requires_arc = false
  	as.source_files = "clucene/src/core/CLucene/**/*.{c,cpp}"
  	as.header_mappings_dir = 'clucene/src/core'
  	as.exclude_files = "clucene/src/core/CLucene/CLMonolithic.*",
  						"clucene/src/core/CLucene/search/FilterResultCache.*",
  						"clucene/src/core/CLucene/queryParser/legacy"
    as.dependency 'BRFullTextSearch/CLucene-Core-API'
    as.dependency 'BRFullTextSearch/CLucene-Shared'
  end

  s.subspec 'CLucene-Contribs-Lib' do |as|
  	as.requires_arc = false
  	as.source_files = "clucene/src/contribs-lib/CLucene/**/*.{h,c,cpp}"
  	as.header_mappings_dir = 'clucene/src/contribs-lib'
    as.dependency 'BRFullTextSearch/CLucene-Core'
    as.dependency 'BRFullTextSearch/CLucene-Shared'
  end

end
