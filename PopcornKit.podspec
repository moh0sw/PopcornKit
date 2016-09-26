Pod::Spec.new do |s|
  s.name = "PopcornKit"
  s.version = "1.1.0.11"
  s.summary = "Backend for Popcorn Time iOS and tvOS."
  s.homepage = "https://github.com/PopcornTimeTV/PopcornKit"
  s.license = 'MIT'
  s.author = { "PopcornTimeTV" => "popcorn@time.tv" }
  s.source = { :git => "https://github.com/PopcornTimeTV/PopcornKit.git", :tag => s.version }

  s.platforms = { :ios => "9.0", :tvos => "9.0" }
  s.requires_arc = true

  s.source_files = 'PopcornKit/**/*.{swift,h,m}'

  s.frameworks = 'UIKit', 'Foundation', 'SafariServices'
  s.module_name = 'PopcornKit'

  s.dependency 'Alamofire'
  s.dependency 'ObjectMapper'
  s.dependency 'AlamofireXMLRPC'
  s.ios.dependency 'SRT2VTT', :git => 'https://github.com/PopcornTimeTV/AlamofireXMLRPC.git'
end
