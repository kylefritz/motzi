require "aws-sdk-s3"

namespace :s3 do
  desc "Download images from s3"
  task :download => :environment do
    s3 = Aws::S3::Client.new
    bucket = "motzi"
    objects = Aws::S3::Client.new.list_objects(bucket: bucket).contents

    # skip the variants; made on demand
    objects = objects.reject { |o| o.key.starts_with?("variants") }

    puts "Saving s3 objects to local disk"
    bar = ProgressBar.new(objects.count)
    objects.each do |object|
      storage_path = Rails.root.join("storage/#{object.key[0..1]}/#{object.key[2..3]}")
      storage_path.mkpathw
      s3.get_object(response_target: storage_path.join(object.key),
                    bucket: bucket,
                    key: object.key)
      bar.increment!
    end
  end
end
