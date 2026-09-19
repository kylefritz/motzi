require "test_helper"

# Renders every mailer preview (test/mailers/previews) so a broken .mjml
# template or shared_mailer partial fails the per-PR suite, not just the
# monthly Playwright visual job. One test per preview email, named after it.
class MailerPreviewsTest < ActionMailer::TestCase
  setup do
    # Previews read Menu.current, Order.last, CreditItem.last, User.last and
    # AnomalyAnalysis.last. Fixtures cover the records; point Menu.current at one.
    menus(:week1).make_current!
  end

  # Guard against the loop below silently generating zero tests (e.g. if
  # preview_paths stops pointing at test/mailers/previews).
  test "every preview file is discovered" do
    files = Dir[Rails.root.join("test/mailers/previews/*_mailer_preview.rb")].map { |f| File.basename(f, "_preview.rb") }
    discovered = ActionMailer::Preview.all.select { |p| p.emails.any? }.map(&:preview_name)
    assert_equal (files - [ "application_mailer" ]).sort, discovered.sort
  end

  ActionMailer::Preview.all.each do |preview|
    preview.emails.each do |email_name|
      test "#{preview.preview_name}##{email_name} preview renders" do
        message = preview.call(email_name)

        refute_equal "Preview unavailable", message.subject,
          "preview fell back to missing(): #{message.body.decoded.strip}"
        assert message.subject.present?, "subject is blank"
        assert message.to.present?, "no recipient"

        expected = expected_content_types(preview.preview_name, email_name)
        assert expected.any?, "no templates found for #{preview.preview_name}/#{email_name}"
        expected.each do |type|
          part = part_for(message, type)
          assert part, "missing #{type} part"
          assert part.body.decoded.strip.present?, "#{type} part is empty"
        end
      end
    end
  end

  private

  # Derive the expected parts from the templates on disk, so text-only mailers
  # aren't asked for an html part. .mjml compiles to html.
  def expected_content_types(mailer, action)
    templates = Dir[Rails.root.join("app/views", mailer, "#{action}.*")].map { |f| File.basename(f) }
    types = []
    types << "text/html" if templates.any? { |t| t.end_with?(".mjml", ".html.erb") }
    types << "text/plain" if templates.any? { |t| t.include?(".text.") }
    types
  end

  def part_for(message, type)
    return message if !message.multipart? && message.mime_type == type

    message.all_parts.find { |p| p.mime_type == type }
  end
end
