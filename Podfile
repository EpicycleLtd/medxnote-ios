platform :ios, '9.0'
source 'https://github.com/CocoaPods/Specs.git'

target 'Medxnote' do
    pod 'Mantle', :inhibit_warnings => true    
    pod 'YapDatabase/SQLCipher', '~> 2.9.3', :inhibit_warnings => true    
    pod 'ATAppUpdater', :inhibit_warnings => true
    pod 'AxolotlKit',                 git: 'https://github.com/WhisperSystems/SignalProtocolKit.git'
    #pod 'AxolotlKit',                 path: '../SignalProtocolKit'
    pod 'JSQMessagesViewController',  git: 'https://github.com/WhisperSystems/JSQMessagesViewController.git', branch: 'signal-master', :inhibit_warnings => true
    #pod 'JSQMessagesViewController',   path: '../JSQMessagesViewController'
    pod 'PureLayout', :inhibit_warnings => true
    pod 'OpenSSL',                    git: 'https://github.com/WhisperSystems/OpenSSL-Pod', inhibit_warnings: true
    pod 'Reachability', :inhibit_warnings => true
    pod 'SignalServiceKit',           path: '.'
    pod 'SocketRocket',               :git => 'https://github.com/facebook/SocketRocket.git', :inhibit_warnings => true
    pod 'YYImage'
    pod 'TOPasscodeViewController'
    pod 'ActionSheetPicker-3.0'

    target 'MedxnoteTests' do
      inherit! :search_paths
    end

    post_install do |installer|
      # Disable some asserts when building for tests
      set_building_for_tests_config(installer, 'SignalServiceKit')
    end
end

# There are some asserts and debug checks that make testing difficult - e.g. Singleton asserts
def set_building_for_tests_config(installer, target_name)
  target = installer.pods_project.targets.detect { |target| target.to_s == target_name }
  if target == nil
    throw "failed to find target: #{target_name}"
  end

  build_config_name = "Test"
  build_config = target.build_configurations.detect { |config| config.to_s == build_config_name }
  if build_config == nil
    throw "failed to find config: #{build_config_name} for target: #{target_name}"
  end

  puts "--[!] Disabling singleton enforcement for target: #{target} in config: #{build_config}"
  existing_definitions = build_config.build_settings['GCC_PREPROCESSOR_DEFINITIONS']

  if existing_definitions == nil || existing.length == 0
    existing_definitions = "$(inheritied)"
  end
  build_config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = "#{existing_definitions} POD_CONFIGURATION_TEST=1 COCOAPODS=1 SSK_BUILDING_FOR_TESTS=1"
end

