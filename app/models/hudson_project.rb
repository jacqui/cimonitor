class HudsonProject < Project
  validates_format_of :feed_url, :with =>  /http:\/\/.*job\/.*\/rssAll$/

  before_save :update_base_path

  def project_name
    return nil if feed_url.nil?
    URI.parse(feed_url).path.scan(/^.*job\/(.*)/i)[0][0].split('/').first
  end

  def build_status_url
    return nil if feed_url.nil?

    url_components = URI.parse(feed_url)
    base_uri = nil
    if url_components.path.match(%r|/(\w+)/job|)
      base_uri = "/#{$1}"
    end

    returning("#{url_components.scheme}://#{url_components.host}") do |url|
      url << ":#{url_components.port}" if url_components.port
      url << "#{base_uri}/cc.xml"
    end
  end

  def parse_building_status(content)
    status = super(content)
    document = Nokogiri::XML.parse(content.downcase)
    p_element = document.xpath("//project[@name=\"#{project_name.downcase}\"]")
    return status if p_element.empty?
    status.building = p_element.attribute('activity').value == 'building'
    status
  end

  def parse_project_status(content)
    status = super(content)
    begin
      latest_build = Nokogiri::XML.parse(content.downcase).css('feed entry:first').first
      status.success = !!(find(latest_build, 'title').first.content =~ /success|stable/)
      status.url = find(latest_build, 'link').first.attribute('href').value
      pub_date = Time.parse(find(latest_build, 'published').first.content)
      status.published_at = (pub_date == Time.at(0) ? Clock.now : pub_date).localtime
    rescue
    end
    status
  end

  def find(document, path)
    document.css("#{path}") if document
  end

  def update_base_path
    return if feed_url.blank?

    path = nil
    if feed_url.match(%r|/(\w+)/job|)
      path = "/#{$1}"
    end
    return if path.nil?

    self.base_path = path
  end
end
