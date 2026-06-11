require "open-uri"
require "aws-sdk-s3"

namespace :marketing do
  # One-shot: download images from wixstatic.com and re-upload to s3://motzi/public/marketing/
  # Run locally: DISABLE_SPRING=1 bin/rails marketing:fetch_assets
  desc "Download marketing images from Wix and upload to S3"
  task fetch_assets: :environment do
    # Each entry: { url: original media URL (S3 key/filename derives from this),
    #               fetch: optional Wix /v1/fill/ rendition to download instead, for assets
    #                      whose originals are far larger than their rendered size }
    sources = [
      # logo & chrome
      { url: "https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png",  # Motzi logo (renders 81x54; fetch 4x rendition)
        fetch: "https://static.wixstatic.com/media/0e6926_461ca570e24f4af18aff571baa07cea2~mv2.png/v1/fill/w_324,h_216,al_c/logo.png" },
      { url: "https://static.wixstatic.com/media/40898a93cfff4578b1779073137eb1b4.png" },             # Instagram icon
      # home
      { url: "https://static.wixstatic.com/media/0e6926_2bd61b90080c4d7f895840a4ab150e5e~mv2.jpg" },  # Kate Haberer hero illustration
      { url: "https://static.wixstatic.com/media/0e6926_d691f726677c4cc494d88c9d2537c1b5~mv2.jpg" },  # sesame loaves on rack (NM_20200702_11_41_38-2)
      { url: "https://static.wixstatic.com/media/0e6926_ececf75ee6654d0ba81ad8c1f15f45f1~mv2.jpg" },  # owners with flowers and bread / home Your Neighbors (NM_20200702_12_48_55)
      # about
      { url: "https://static.wixstatic.com/media/nsplsh_685133575a6e5933795a30~mv2_d_5906_3937_s_4_2.jpg",  # flour texture / about hero background (5906x3937 original; 1920px is plenty)
        fetch: "https://static.wixstatic.com/media/nsplsh_685133575a6e5933795a30~mv2_d_5906_3937_s_4_2.jpg/v1/fill/w_1920,h_1280,al_c,q_75/hero.jpg" },
      { url: "https://static.wixstatic.com/media/0e6926_01f6d2dd66064697bac0356b585c9d7c~mv2.jpg" },  # owners at counter / about hero (NM_20200723_14_12_12)
      { url: "https://static.wixstatic.com/media/0e6926_1311a5b3a98046e89ac6c75f1fdbf9fc~mv2.jpg" },  # Heinz Thomet / harvesting oats
      { url: "https://static.wixstatic.com/media/0e6926_1de8dfb61580466085fe1a216c5d656a~mv2.jpg" },  # flour mill interior (NM_20200702_12_58_37)
      { url: "https://static.wixstatic.com/media/0e6926_e97ddc3e63db4331946b5d84e1d8e392~mv2.jpg" },  # storefront window papercut art (NM_20200702_12_11_36)
    ]

    s3 = Aws::S3::Resource.new(region: "us-east-1")
    bucket = s3.bucket("motzi")

    map = []
    sources.each do |source|
      url = source[:url]
      fetch_url = source[:fetch] || url
      filename = File.basename(URI(url).path).gsub(/[^A-Za-z0-9._-]/, "_")
      key = "public/marketing/#{filename}"
      puts "Downloading #{fetch_url}..."
      data = URI.open(fetch_url, "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36").read
      bucket.object(key).put(body: data, content_type: Marcel::MimeType.for(StringIO.new(data)))
      s3_url = "https://motzi.s3.us-east-1.amazonaws.com/#{key}"
      map << { original: url, s3: s3_url }
      puts "  -> #{s3_url}"
    end

    puts "\n## Asset map\n\n| Original | S3 |\n|---|---|"
    map.each { |m| puts "| `#{m[:original]}` | `#{m[:s3]}` |" }
  end
end
