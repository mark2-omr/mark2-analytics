module ApplicationHelper
  def default_meta_tags
    {
      site: "Mark2 Analytics",
      title: nil,
      reverse: true,
      separator: "|",
      description: "",
      keywords: "Mark2",
      canonical: request.original_url,
      noindex: !Rails.env.production?,
      icon: [
        { href: image_url("favicon.svg") },
        {
          href: image_url("favicon.png"),
          rel: "apple-touch-icon",
          sizes: "180x180",
          type: "image/png",
        },
      ],
      og: {
        site_name: "Mark2 Analytics",
        title: nil,
        description: "",
        type: "website",
        url: request.original_url,
        image: image_url("connected-world-rafiki.png"),
        locale: "ja_JP",
      },
    }
  end
end
