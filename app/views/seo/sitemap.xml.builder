xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @paths.each do |path|
    xml.url do
      xml.loc marketing_url(path)
    end
  end
end
