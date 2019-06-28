# frozen_string_literal: true

require 'esa'

class EsaClient
  POST_URL_PATTERN = /\Ahttps:\/\/([\w-]+)\.esa\.io\/posts\/(\d+)(\/.*)?\z/.freeze

  def initialize
    @client = Esa::Client.new(access_token: ENV['ESA_ACCESS_TOKEN'])
  end

  def enabled?
    ENV['ESA_ACCESS_TOKEN']
  end

  def target?(url)
    url =~ POST_URL_PATTERN
  end

  def get(url)
    return nil unless url =~ POST_URL_PATTERN

    begin
      @client.current_team = $1
      post = @client.post($2.to_i).body

      info = {
        title: post['full_name'],
        title_link: post['url'],
        author_name: post['updated_by']['screen_name'],
        author_icon: post['updated_by']['icon'],
        text: post['body_md'].lines[0, 10].map { |item| item.chomp }.join("\n"),
        color: '#3E8E89'
      }

      return info
    rescue => e
      puts e.inspect
      nil
    end
  end

end
