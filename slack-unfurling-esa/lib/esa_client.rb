# frozen_string_literal: true

require 'esa'

class EsaClient
  POST_URL_PATTERN = /\Ahttps:\/\/([\w-]+)\.esa\.io\/posts\/(\d+)(.*)?\z/.freeze
  ESA_COLOR = '#3E8E89'

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
      post = @client.post($2.to_i, include: :comments).body

      if $3 =~ /#comment-(\d+)/
        comment = post['comments'].find { |c| c['id'] == $1.to_i }
        return nil unless comment

        info = {
          title: post['full_name'],
          title_link: comment['url'],
          author_name: comment['created_by']['screen_name'],
          author_icon: comment['created_by']['icon'],
          text: truncate(comment['body_md']),
          color: ESA_COLOR
        }
      else
        info = {
          title: post['full_name'],
          title_link: post['url'],
          author_name: post['updated_by']['screen_name'],
          author_icon: post['updated_by']['icon'],
          text: truncate(post['body_md']),
          color: ESA_COLOR
        }
      end

      return info
    rescue => e
      puts e.inspect
      nil
    end
  end

  private

  def truncate(body)
    body.lines[0, 10].map { |item| item.chomp }.join("\n")
  end
end
