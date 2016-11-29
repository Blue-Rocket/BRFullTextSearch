source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!

install! 'cocoapods', :deterministic_uuids => false

abstract_target 'BasePods' do
	pod 'BRCLucene', '~> 1.0.0-beta1'

	target 'BRFullTextSearch' do
		platform :ios, '5.1'
	end

	target 'BRFullTextSearchTests' do
		platform :ios, '5.1'
	end

	target 'BRFullTextSearch Mac OS' do
		platform :osx, '10.7'
	end
end
