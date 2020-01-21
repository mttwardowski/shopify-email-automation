class MailfunnelsUtil

  def self.get_app_name

    domain = 'bluehelmet-dev.myshopify.com'

    begin
      domain = ShopifyAPI::Shop.current.domain

      if cookies.permanent[:shopify_app] == nil
        cookies.permanent[:shopify_app] = "bluehelmet-dev.myshopify.com"
      end

    rescue => e
      # logger.error(e.message)
    end

    return domain
  end

  def self.get_app_id
    return App.where(name: MailfunnelsUtil.get_app_name).first.id
  end

  def self.get_app
    return App.where(name: MailfunnelsUtil.get_app_name).first
  end

end