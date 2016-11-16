# flurry plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-flurry)

## Getting Started

This project is a [fastlane](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-flurry`, add it to your project by running:

```bash
fastlane add_plugin flurry
```

## About flurry

This action allows you to upload symbolication files to Flurry.

```ruby
flurry_upload_dsym(
  api_key: '...',
  auth_token: '...',
  dsym_path: './Example.app.dSYM.zip'
)
```

The following environment variables may be used in place of parameters: `FLURRY_API_KEY`, `FLURRY_AUTH_TOKEN`, and `FLURRY_DSYM_PATH`.

## Example Fastfile
```
fastlane_version "1.108.0"
 
default_platform :ios
 
platform :ios do
 
  ENV['FLURRY_AUTH_TOKEN'] = '<Put-Token-Here>'
  ENV['FLURRY_API_KEY'] = '<Put-API-Key-Here>' # Use your own API Key Here
  
  desc "Build for non-bitcode enabled apps. Includes uploading dSYMs"
  lane :build do
    cert
    sigh
    gym(scheme: "AppName")
    flurry_upload_dsym
    clean_build_artifacts
  end
  
  desc "Upload dSYMs for bitcode enabled apps"
  lane :upload_symbols do
    download_dsyms
    flurry_upload_dsym
    clean_build_artifacts
  end
end
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/PluginsTroubleshooting.md) doc in the main `fastlane` repo.

## Using `fastlane` Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://github.com/fastlane/fastlane/blob/master/fastlane/docs/Plugins.md).

## About `fastlane`

`fastlane` is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
