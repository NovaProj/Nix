Pod::Spec.new do |s|
    s.name = 'Nix'
    s.version = '0.9'
    s.license = 'MIT'
    s.summary = 'Network Interface eXtension for easy and structured API calls'
    s.homepage = 'https://github.com/NovaProj/Nix'
    s.authors = { 'Bazyli Zygan' => 'bazyl@novaproject.net' }
    s.source = { :git => 'https://github.com/NovaProj/Nix.git', :tag => s.version }

    s.ios.deployment_target = '9.0'
    s.osx.deployment_target = '10.10'
    s.tvos.deployment_target = '9.0'
    s.watchos.deployment_target = '2.0'

    s.source_files = 'Sources/*.swift'
end
