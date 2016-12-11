use_frameworks!

source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/angryDuck2/CocoaSpecs'

def pods
 pod 'Alamofire', '~> 4.0.0'
 pod 'ObjectMapper'
 pod 'AlamofireXMLRPC'
 pod 'SwiftyJSON'
 pod 'Locksmith'
end

target 'PopcornKit tvOS' do
    platform :tvos, '9.0'
    pods
end

target 'PopcornKit iOS' do
    platform :ios, '9.0'
    pods
    pod 'google-cast-sdk', '~> 3.2'
    pod 'SRT2VTT', '~> 1.0.1'
end
