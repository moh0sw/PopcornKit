use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'

def pods
  pod 'Alamofire'
  pod 'ObjectMapper'
  pod 'AlamofireXMLRPC', git: 'https://github.com/PopcornTimeTV/AlamofireXMLRPC.git'
end

target 'PopcornKit tvOS' do
    platform :tvos, '9.0'
    pods
end

target 'PopcornKit iOS' do
    platform :ios, '9.0'
    pods
    pod 'SRT2VTT'
end
