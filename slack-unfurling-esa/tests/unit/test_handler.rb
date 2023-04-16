# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/stub_any_instance'
require 'webmock/minitest'

require_relative '../../app.rb'

class AppTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def event(body)
    {
      'body' => body,
    }
  end

  def test_url_verification_404
    e = event({
      type: 'url_verification'
    }.to_json)

    expected_result = { statusCode: 404, body: JSON.generate(ok: false) }

    assert_equal(expected_result, lambda_handler(event: e, context: ''))
  end

  def test_url_verification_200
    e = event({
      type: 'url_verification',
      challenge: 'example'
    }.to_json)

    expected_result = { statusCode: 200, body: JSON.generate(challenge: 'example') }

    EsaClient.stub_any_instance(:'enabled?', true) do
      assert_equal(expected_result, lambda_handler(event: e, context: ''))
    end
  end

  def test_event_callback_page
    e = event({
      type: 'event_callback',
      event: {
        channel: 'channel_name',
        message_ts: '1234567890.123456',
        links: [
          { url: 'https://docs.esa.io/posts/367' }
        ]
      }
    }.to_json)

    stub_request(:get, 'https://api.esa.io/v1/teams/docs/posts/367?include=comments').
      to_return(status: 200, body: {
        full_name: 'full_name',
        url: 'url',
        updated_by: {
          screen_name: 'scree_name',
          icon: 'icon'
        },
        body_md: 'body_md'
      }.to_json, headers: {'content-type': 'application/json'})

    stub_request(:post, 'https://slack.com/api/chat.unfurl').
    with(
      body: {
        channel: 'channel_name',
        ts: '1234567890.123456',
        unfurls: {
          'https://docs.esa.io/posts/367': {
            title: 'full_name',
            title_link: 'url',
            author_name: 'scree_name',
            author_icon: 'icon',
            text: 'body_md',
            color: '#3E8E89'
          }
        }
      }.to_json).
      to_return(status: 200, body: "", headers: {'content-type': 'application/json'})

    expected_result = { statusCode: 200, body: JSON.generate(ok: true) }

    EsaClient.stub_any_instance(:'enabled?', true) do
      assert_equal(expected_result, lambda_handler(event: e, context: ''))
    end
  end

  def test_event_callback_comment
    e = event({
      type: 'event_callback',
      event: {
        channel: 'channel_name',
        message_ts: '1234567890.123456',
        links: [
          { url: 'https://docs.esa.io/posts/367#comment-123' }
        ]
      }
    }.to_json)

    stub_request(:get, 'https://api.esa.io/v1/teams/docs/posts/367?include=comments').
      to_return(status: 200, body: {
        full_name: 'full_name',
        comments: [
          {
            id: 123,
            url: 'comment_url',
            created_by: {
              screen_name: 'comment_scree_name',
              icon: 'comment_icon'
            },
            body_md: 'comment_body_md'
          }
        ]
      }.to_json, headers: {'content-type': 'application/json'})

    stub_request(:post, 'https://slack.com/api/chat.unfurl').
    with(
      body: {
        channel: 'channel_name',
        ts: '1234567890.123456',
        unfurls: {
          'https://docs.esa.io/posts/367#comment-123': {
            title: 'full_name',
            title_link: 'comment_url',
            author_name: 'comment_scree_name',
            author_icon: 'comment_icon',
            text: 'comment_body_md',
            color: '#3E8E89'
          }
        }
      }.to_json).
      to_return(status: 200, body: "", headers: {'content-type': 'application/json'})

    expected_result = { statusCode: 200, body: JSON.generate(ok: true) }

    EsaClient.stub_any_instance(:'enabled?', true) do
      assert_equal(expected_result, lambda_handler(event: e, context: ''))
    end
  end
end
