use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'

def pods
 pod 'Alamofire', '~> 4.0.0'
 pod 'ObjectMapper', '~> 2.0.0'
 pod 'AlamofireXMLRPC', :git => 'https://github.com/PopcornTimeTV/AlamofireXMLRPC.git'
end

target 'PopcornKit tvOS' do
    platform :tvos, '9.0'
    pods
end

target 'PopcornKit iOS' do
    platform :ios, '9.0'
    pods
    pod 'SRT2VTT', '~> 1.0.1'
end
