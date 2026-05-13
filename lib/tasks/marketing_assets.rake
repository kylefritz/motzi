require "open-uri"
require "aws-sdk-s3"

namespace :marketing do
  # One-shot: download images from wixstatic.com and re-upload to s3://motzi/public/marketing/
  # Run locally: bundle exec rake marketing:fetch_assets
  desc "Download marketing images from Wix and upload to S3"
  task fetch_assets: :environment do
    sources = [
      # --- Shared (logo + social) ---
      {
        url: "https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png",
        name: "Motzi_logo_web_edited_edited.png"
      },
      {
        url: "https://static.wixstatic.com/media/40898a93cfff4578b1779073137eb1b4.png",
        name: "instagram_icon.png"
      },

      # --- Home page ---
      {
        url: "https://static.wixstatic.com/media/0e6926_2bd61b90080c4d7f895840a4ab150e5e~mv2.jpg",
        name: "Kate_drawing_hero.jpg"
      },
      {
        url: "https://static.wixstatic.com/media/0e6926_d691f726677c4cc494d88c9d2537c1b5~mv2.jpg",
        name: "NM_20200702_11_41_38-2_websize.jpg"
      },
      {
        url: "https://static.wixstatic.com/media/0e6926_ececf75ee6654d0ba81ad8c1f15f45f1~mv2.jpg",
        name: "NM_20200702_12_48_55_websize.jpg"
      },

      # --- About page (scraped from live site 2026-05-12) ---
      {
        url: "https://static.wixstatic.com/media/nsplsh_685133575a6e5933795a30~mv2_d_5906_3937_s_4_2.jpg",
        name: "nsplsh_685133575a6e5933795a30~mv2_d_5906_3937_s_4_2.jpg"
      },
      {
        url: "https://static.wixstatic.com/media/0e6926_01f6d2dd66064697bac0356b585c9d7c~mv2.jpg",
        name: "NM_20200723_14_12_12_websize_edited.jpg"
      },
      {
        url: "https://static.wixstatic.com/media/0e6926_1311a5b3a98046e89ac6c75f1fdbf9fc~mv2.jpg",
        name: "harvesting-hulless-oats.jpg"
      },
      {
        url: "https://static.wixstatic.com/media/0e6926_1de8dfb61580466085fe1a216c5d656a~mv2.jpg",
        name: "NM_20200702_12_58_37_websize.jpg"
      },
      {
        url: "https://static.wixstatic.com/media/0e6926_e97ddc3e63db4331946b5d84e1d8e392~mv2.jpg",
        name: "NM_20200702_12_11_36_websize.jpg"
      },
    ]

    s3 = Aws::S3::Resource.new(region: "us-east-1")
    bucket = s3.bucket("motzi")

    map = []
    sources.each do |source|
      url  = source[:url]
      name = source[:name].gsub(/[^A-Za-z0-9._-]/, "_")
      key  = "public/marketing/#{name}"

      puts "Downloading #{url}..."
      begin
        data         = URI.open(url).read
        content_type = Marcel::MimeType.for(StringIO.new(data), name: name)
        # No ACL needed — public/marketing/ prefix is publicly readable at the bucket policy level
        bucket.object(key).put(body: data, content_type: content_type)
        s3_url = "https://motzi.s3.us-east-1.amazonaws.com/#{key}"
        map << { original: url, s3: s3_url, name: name }
        puts "  -> #{s3_url}"
      rescue OpenURI::HTTPError => e
        warn "  SKIP: #{url} — #{e.message} (URL may have been removed from Wix CDN)"
      end
    end

    puts "\n## Asset map\n\n| Name | Original | S3 |\n|---|---|---|"
    map.each { |row| puts "| `#{row[:name]}` | `#{row[:original]}` | `#{row[:s3]}` |" }
  end
end
