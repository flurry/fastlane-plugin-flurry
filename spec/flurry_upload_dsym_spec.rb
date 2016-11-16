#  Created by Akash Duseja 11/16/2016
#  Copyright (c) 2016 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

describe Fastlane do
  describe Fastlane::FastFile do
    describe "flurry" do
      before do
        stub_request(:get, "https://crash-metadata.flurry.com/pulse/v1/project?fields%5Bproject%5D=apiKey&filter%5Bproject.apiKey%5D=good_api_key").
            with(:headers => {'Accept'=>'application/vnd.api+json', 'Authorization'=>'Bearer good_auth_token', 'Content-Type'=>'application/vnd.api+json'}).
            to_return(:status => 200, :body => File.read("./spec/fixtures/requests/flurry_metadata_get_project_response.json"), :headers => {'Content-Type'=>'application/vnd.api+json'})

        stub_request(:get, "https://crash-metadata.flurry.com/pulse/v1/project?fields%5Bproject%5D=apiKey&filter%5Bproject.apiKey%5D=good_api_key").
            with(:headers => {'Accept'=>'application/vnd.api+json', 'Authorization'=>'Bearer bad_auth_token', 'Content-Type'=>'application/vnd.api+json'}).
            to_return(:status => 401, :body => "", :headers => {})

        stub_request(:get, "https://crash-metadata.flurry.com/pulse/v1/project?fields%5Bproject%5D=apiKey&filter%5Bproject.apiKey%5D=bad_api_key").
            with(:headers => {'Accept'=>'application/vnd.api+json', 'Authorization'=>'Bearer good_auth_token', 'Content-Type'=>'application/vnd.api+json'}).
            to_return(:status => 200, :body => "{\"data\":[]}", :headers => {})

        stub_request(:post, "https://crash-metadata.flurry.com/pulse/v1/project/99999999/uploads").
            with(:body => /.*?/,
                 :headers => {'Accept'=>'application/vnd.api+json', 'Authorization'=>'Bearer good_auth_token', 'Content-Type'=>'application/vnd.api+json'}).
            to_return(:status => 201, :body => File.read("./spec/fixtures/requests/flurry_metadata_post_upload_response.json"), :headers => {'Content-Type'=>'application/vnd.api+json'})

        stub_request(:post, "https://upload.flurry.com/upload/v1/upload/99999999/88888888").
            with(:body => /.*?/,
                 :headers => {'Authorization'=>'Bearer good_auth_token', 'Content-Type'=>'application/octet-stream', 'Content-Length' => /.*?/}).
            to_return(:status => 202, :body => "{\"status\":\"upload succeeded\"}", :headers => {})

        stub_request(:get, "https://crash-metadata.flurry.com/pulse/v1/project/99999999/uploads/88888888?fields%5Bupload%5D=uploadStatus,failureReason").
            with(:headers => {'Accept'=>'application/vnd.api+json', 'Authorization'=>'Bearer good_auth_token', 'Content-Type'=>'application/vnd.api+json'}).
            to_return(:status => 200, :body => File.read("./spec/fixtures/requests/flurry_metadata_get_upload_status_response.json"), :headers => {'Content-Type'=>'application/vnd.api+json'})
      end

      it "uploads dSYM files" do
        dsym_path_1 = './fastlane-plugin-flurry/spec/fixtures/dSYM/Example.app.dSYM'
        Fastlane::FastFile.new.parse("lane :test do
            flurry_upload_dsym(
              api_key: 'good_api_key',
              auth_token: 'good_auth_token',
              dsym_path: '#{dsym_path_1}')
          end").runner.execute(:test)
      end

      it "uploads dSYM.zip files" do
        dsym_path_1 = './fastlane-plugin-flurry/spec/fixtures/dSYM/zipped/Example.app.dSYM.zip'
        Fastlane::FastFile.new.parse("lane :test do
            flurry_upload_dsym(
              api_key: 'good_api_key',
              auth_token: 'good_auth_token',
              dsym_path: '#{dsym_path_1}')
          end").runner.execute(:test)
      end

      it "fails with a bad auth_token" do
        dsym_path_1 = './fastlane-plugin-flurry/spec/fixtures/dSYM/Example.app.dSYM'
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            flurry_upload_dsym(
              api_key: 'good_api_key',
              auth_token: 'bad_auth_token',
              dsym_path: '#{dsym_path_1}')
          end").runner.execute(:test)
        end.to raise_error("Invalid/Expired Auth Token Provided. Please obtain a new token and try again.")
      end

      it "fails with a bad api_key" do
        dsym_path_1 = './fastlane-plugin-flurry/spec/fixtures/dSYM/Example.app.dSYM'
        expect do
          Fastlane::FastFile.new.parse("lane :test do
            flurry_upload_dsym(
              api_key: 'bad_api_key',
              auth_token: 'good_auth_token',
              dsym_path: '#{dsym_path_1}')
          end").runner.execute(:test)
        end.to raise_error("No project found for the provided API Key. Make sure the provided API key is valid and the user has access to that project.")
      end
    end
  end
end
