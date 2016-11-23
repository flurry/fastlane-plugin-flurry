#  Created by Akash Duseja 11/16/2016
#  Copyright (c) 2016 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

module Fastlane
  module Actions
    class FlurryUploadDsymAction < Action

      METADATA_BASE_URL = 'https://crash-metadata.flurry.com/pulse/v1'
      UPLOAD_BASE_URL = 'https://upload.flurry.com/upload/v1'

      def self.run(params)
        Actions.verify_gem!('rest-client')
        require 'rest-client'
        require 'rubygems/package'

        # Params - API
        api_key = params[:api_key]
        auth_token = params[:auth_token]
        timeout_in_s = params[:timeout_in_s]
        project_id = find_project(api_key, auth_token)

        # Params - dSYM
        dsym_paths = []
        dsym_paths += [params[:dsym_path]] if params[:dsym_path]
        dsym_paths += params[:dsym_paths] if params[:dsym_paths]

        if dsym_paths.count == 0
          UI.user_error! "Couldn't find any DSYMs. Please pass them using the dsym_path option)"
        end

        dsym_paths.compact.map do | single_dsym_path |
          if single_dsym_path.end_with?('.zip')
            UI.message("Extracting '#{single_dsym_path}'...")
            single_dsym_path = unzip_file(single_dsym_path)
          end

          tar_zip_file = tar_zip_file(single_dsym_path)
          upload_id = create_upload(tar_zip_file.size, project_id, auth_token)
          send_to_upload_service(tar_zip_file.path, project_id, upload_id, auth_token)
          check_upload_status(project_id, upload_id, auth_token, timeout_in_s)
        end

        UI.message "Successfully Uploaded the provided dSYMs to Flurry."
      end

      def self.unzip_file (file)
        dir = Dir.mktmpdir
        Zip::File.open(file) do |zip_file|
          zip_file.each do |f|
            f_path=File.join(dir, f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
            zip_file.extract(f, f_path) unless File.exist?(f_path)
          end
        end
        dir
      end

      def self.find_project(api_key, auth_token)
        begin
          response = RestClient.get "#{METADATA_BASE_URL}/project?fields[project]=apiKey&filter[project.apiKey]=#{api_key}", get_metadata_headers(auth_token)
        rescue => e
          UI.user_error! "Invalid/Expired Auth Token Provided. Please obtain a new token and try again."
        end

        json_response_data = JSON.parse(response.body)["data"]
        if json_response_data.count == 0
          UI.user_error! "No project found for the provided API Key. Make sure the provided API key is valid and the user has access to that project."
        end
        return json_response_data[0]["id"]
      end

      def self.tar_zip_file(dsym_path)
        tar_zip_file = Tempfile.new(['temp','.tar.gz'])
        io = gzip_file(tar_file(dsym_path))
        tar_zip_file.binmode
        tar_zip_file.write io.read
        tar_zip_file.close
        return tar_zip_file
      end

      def self.tar_file(dsym_path)
        tarfile = StringIO.new("")
        Gem::Package::TarWriter.new(tarfile) do |tar|
          Dir[File.join(dsym_path, "**/*")].each do |file|
            mode = File.stat(file).mode
            relative_file = file.sub /^#{Regexp::escape dsym_path}\/?/, ''

            if File.directory?(file)
              tar.mkdir relative_file, mode
            else
              tar.add_file relative_file, mode do |tf|
                File.open(file, "rb") { |f| tf.write f.read }
              end
            end
          end
        end
        tarfile.rewind
        return tarfile
      end

      def self.gzip_file(tar_file)
        gz = StringIO.new("")
        z = Zlib::GzipWriter.new(gz)
        z.write tar_file.string
        z.close
        StringIO.new gz.string
      end

      def self.create_upload(size, project_id, auth_token)
        payload = "{\"data\": {\"type\": \"upload\", \"attributes\": {\"uploadType\": \"IOS\", \"contentLength\": #{size}}, \"relationships\": {\"project\": {\"data\": {\"id\": #{project_id},\"type\": \"project\"}}}}}"
        response = RestClient.post "#{METADATA_BASE_URL}/project/#{project_id}/uploads", payload, get_metadata_headers(auth_token)
        if response.code != 201
          UI.user_error! "Failed to create Upload with Status Code: #{response.code}"
        end
        jsonResponse = JSON.parse(response.body)
        return jsonResponse["data"]["id"]
      end

      def self.send_to_upload_service(file_path, project_id, upload_id, auth_token)
        file = File.new(file_path, 'rb')
        file_size = file.size.to_i
        UI.message "Uploading..."
        response = RestClient.post "#{UPLOAD_BASE_URL}/upload/#{project_id}/#{upload_id}", file, get_upload_headers(file_size, auth_token)
        if response.code != 201 && response.code != 202
          UI.user_error! "Failed to send files to upload service with Status Code: #{response.code}"
        end
      end

      def self.check_upload_status(project_id, upload_id, auth_token, max_duration_seconds)
        time_elapsed = 0
        while time_elapsed < max_duration_seconds.to_i do
          response = RestClient.get "#{METADATA_BASE_URL}/project/#{project_id}/uploads/#{upload_id}?fields[upload]=uploadStatus,failureReason", get_metadata_headers(auth_token)
          json_response = JSON.parse(response.body)
          upload_status = json_response["data"]["attributes"]["uploadStatus"]
          if upload_status == "COMPLETED"
            return
          elsif upload_status == "FAILED"
            reason = json_response["data"]["attributes"]["failureReason"]
            UI.user_error! "Failed to upload the provided dSYMs to Flurry with the following reason: #{reason}"
          end
          sleep 2
          time_elapsed += 2
        end
        UI.user_error! "Timed out after #{time_elapsed} seconds while uploading the provided dSYMs to Flurry"
      end

      def self.get_metadata_headers(auth_token)
        return {:Authorization => "Bearer #{auth_token}", :accept => 'application/vnd.api+json', :content_type => 'application/vnd.api+json'}
      end

      def self.get_upload_headers(size, auth_token)
        range_header = 'bytes 0-' + (size - 1).to_s
        return {:content_type => 'application/octet-stream', :Range => range_header, :Authorization => "Bearer #{auth_token}"}
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload dSYM symbolication files to Flurry"
      end

      def self.details
        [
            "This action allows you to upload symbolication files to Flurry.",
            "It's extra useful if you use it to download the latest dSYM files from Apple when you",
            "use Bitcode"
        ].join(" ")
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(key: :api_key,
                                         env_name: 'FLURRY_API_KEY',
                                         description: 'Flurry API Key',
                                         verify_block: proc do |value|
                                           UI.user_error!("No API Key for Flurry given, pass using `api_key: 'apiKey'`") if value.to_s.length == 0
                                         end),
            FastlaneCore::ConfigItem.new(key: :auth_token,
                                         env_name: 'FLURRY_AUTH_TOKEN',
                                         description: 'Flurry Auth Token',
                                         verify_block: proc do |value|
                                           UI.user_error!("No Auth Token for Flurry given, pass using `auth_token: 'token'`") if value.to_s.length == 0
                                         end),
            FastlaneCore::ConfigItem.new(key: :dsym_path,
                                         env_name: 'FLURRY_DSYM_PATH',
                                         description: 'Path to the DSYM file to upload',
                                         default_value: Actions.lane_context[SharedValues::DSYM_OUTPUT_PATH],
                                         optional: true,
                                         verify_block: proc do |value|
                                           UI.user_error!("Couldn't find file at path '#{File.expand_path(value)}'") unless File.exist?(value)
                                           UI.user_error!('Symbolication file needs to be dSYM or zip') unless value.end_with?('.dSYM', '.zip')
                                         end),
            FastlaneCore::ConfigItem.new(key: :dsym_paths,
                                         env_name: 'FLURRY_DSYM_PATHS',
                                         description: 'Path to an array of your symbols file. For iOS and Mac provide path to app.dSYM.zip',
                                         default_value: Actions.lane_context[SharedValues::DSYM_PATHS],
                                         is_string: false,
                                         optional: true),
            FastlaneCore::ConfigItem.new(key: :timeout_in_s,
                                         env_name: 'TIMEOUT_IN_S',
                                         description: 'Upload Timeout in Seconds',
                                         optional: true,
                                         default_value: '600')
        ]
      end

      def self.authors
        ["duseja2"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end

      def self.example_code
        [
            'flurry_upload_dsym(
            api_key: "...",
            auth_token: "...",
            dsym_path: "./App.dSYM.zip"
          )'
        ]
      end

      def self.category
        :misc
      end
    end
  end
end
