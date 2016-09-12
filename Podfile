use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'


def pods
  pod 'Alamofire' , '~>3.4.2'
  pod 'ObjectMapper'
  pod 'AlamofireXMLRPC', git: 'https://github.com/PopcornTimeTV/AlamofireXMLRPC.git'
end

target 'PopcornKit' do
    platform :tvos, '9.0'
    pods
end

target 'PopcornKitTests' do
    platform :tvos, '9.0'
    pods
end

target 'PopcornKitIOS' do
    platform :ios, '9.0'
    pods
    pod 'SRT2VTT'
end

target 'PopcornKitIOSTests' do
    platform :ios, '9.0'
    pods
    pod 'SRT2VTT'
end
