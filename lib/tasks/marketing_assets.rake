require "open-uri"
require "aws-sdk-s3"

namespace :marketing do
  # One-shot: download images from wixstatic.com and re-upload to s3://motzi/public/marketing/
  # Run locally: DISABLE_SPRING=1 bin/rails marketing:fetch_assets
  desc "Download marketing images from Wix and upload to S3"
  task fetch_assets: :environment do
    sources = [
      # logo & chrome
      "https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png",  # Motzi logo
      "https://static.wixstatic.com/media/40898a93cfff4578b1779073137eb1b4.png",             # Instagram icon
      # home
      "https://static.wixstatic.com/media/0e6926_2bd61b90080c4d7f895840a4ab150e5e~mv2.jpg",  # Kate Haberer hero illustration
      "https://static.wixstatic.com/media/0e6926_d691f726677c4cc494d88c9d2537c1b5~mv2.jpg",  # owners photo (NM_20200702_11_41_38-2)
      "https://static.wixstatic.com/media/0e6926_ececf75ee6654d0ba81ad8c1f15f45f1~mv2.jpg",  # bread photo (NM_20200702_12_48_55)
      # about
      "https://static.wixstatic.com/media/nsplsh_685133575a6e5933795a30~mv2_d_5906_3937_s_4_2.jpg",  # grain-field hero
      "https://static.wixstatic.com/media/0e6926_01f6d2dd66064697bac0356b585c9d7c~mv2.jpg",  # milling (NM_20200723_14_12_12)
      "https://static.wixstatic.com/media/0e6926_1311a5b3a98046e89ac6c75f1fdbf9fc~mv2.jpg",  # Heinz Thomet / harvesting oats
      "https://static.wixstatic.com/media/0e6926_1de8dfb61580466085fe1a216c5d656a~mv2.jpg",  # shaping (NM_20200702_12_58_37)
      "https://static.wixstatic.com/media/0e6926_e97ddc3e63db4331946b5d84e1d8e392~mv2.jpg",  # loaf detail (NM_20200702_12_11_36)
    ]

    s3 = Aws::S3::Resource.new(region: "us-east-1")
    bucket = s3.bucket("motzi")

    map = []
    sources.each do |url|
      filename = File.basename(URI(url).path).gsub(/[^A-Za-z0-9._-]/, "_")
      key = "public/marketing/#{filename}"
      puts "Downloading #{url}..."
      data = URI.open(url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36").read
      bucket.object(key).put(body: data, content_type: Marcel::MimeType.for(StringIO.new(data)))
      s3_url = "https://motzi.s3.us-east-1.amazonaws.com/#{key}"
      map << { original: url, s3: s3_url }
      puts "  -> #{s3_url}"
    end

    puts "\n## Asset map\n\n| Original | S3 |\n|---|---|"
    map.each { |m| puts "| `#{m[:original]}` | `#{m[:s3]}` |" }
  end
end
