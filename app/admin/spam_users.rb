ActiveAdmin.register_page "Spam Users" do
  menu parent: "Advanced", label: "Spam", priority: 7

  controller do
    helper_method :spam_cache_key

    def spam_cache_key
      "spam_scan/#{current_admin_user.id}"
    end
  end

  # Scan with Claude
  page_action :scan, method: :post do
    results = SpamDetector.new.scan
    Rails.cache.write(spam_cache_key, results.to_json, expires_in: 1.hour)
    redirect_to admin_spam_users_path,
                notice: "Claude identified #{results.size} spam accounts."
  end

  # Delete selected users
  page_action :delete_selected, method: :post do
    ids = Array(params[:user_ids]).map(&:to_i).reject(&:zero?)
    if ids.any?
      users = User.where(id: ids).left_joins(:orders).where(orders: { id: nil })
      count = users.count
      users.destroy_all
      Rails.cache.delete(spam_cache_key)
      redirect_to admin_spam_users_path,
                  notice: "Deleted #{count} spam users."
    else
      redirect_to admin_spam_users_path,
                  alert: "No users selected."
    end
  end

  content title: "Spam Users" do
    # Load candidates
    candidates = User.left_joins(:orders)
                     .where(orders: { id: nil })
                     .where("sign_in_count <= 1")
                     .where.not(id: 0)
                     .order(:created_at)

    # Parse scan results from cache
    scan_results = begin
      JSON.parse(Rails.cache.read(spam_cache_key) || "[]", symbolize_names: true)
    rescue JSON::ParserError
      []
    end
    spam_ids = scan_results.map { |r| r[:id] }.to_set
    reasons = scan_results.index_by { |r| r[:id] }

    para "#{candidates.count} users with no orders and 0-1 sign-ins. Use Claude to identify likely spam accounts."

    if candidates.any?
      div class: "spam-toolbar" do
        div class: "spam-toolbar-left" do
          text_node button_to("✦  Scan with Claude",
                             admin_spam_users_scan_path,
                             method: :post,
                             form_class: "spam-scan-form",
                             class: "spam-scan-btn")
          a "Delete Selected", href: "#", id: "delete-selected-btn", class: "spam-delete-btn"
        end
        div class: "spam-toolbar-right" do
          span "#{spam_ids.size} flagged", class: "spam-count" if scan_results.any?
          if spam_ids.any?
            span class: "select-helpers" do
              a "Select flagged", href: "#", id: "select-flagged"
              text_node " · "
              a "Select none", href: "#", id: "select-none"
            end
          end
        end
      end

      form_for :spam, url: admin_spam_users_delete_selected_path, method: :post, html: { id: "spam-users-form" } do |_f|
        table class: "spam-table" do
          thead do
            tr do
              th ""
              th "Name"
              th "Email"
              th "Sign-ins"
              th "Created"
              th "Claude" if scan_results.any?
            end
          end
          tbody do
            candidates.each do |user|
              is_spam = spam_ids.include?(user.id)
              tr class: is_spam ? "spam-flagged" : nil do
                td do
                  check_box_tag "user_ids[]", user.id, is_spam, class: "spam-check"
                end
                td do
                  a "#{user.first_name} #{user.last_name}".strip, href: admin_user_path(user)
                end
                td user.email
                td user.sign_in_count
                td user.created_at.to_date.iso8601
                if scan_results.any?
                  td class: "spam-reason" do
                    if is_spam
                      span reasons[user.id][:reason], class: "reason-text"
                    else
                      span "OK", class: "reason-ok"
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    script do
      text_node <<~JS.html_safe
        document.addEventListener('DOMContentLoaded', function() {
          var flagged = document.getElementById('select-flagged');
          var none = document.getElementById('select-none');
          var deleteBtn = document.getElementById('delete-selected-btn');
          if (flagged) {
            flagged.addEventListener('click', function(e) {
              e.preventDefault();
              document.querySelectorAll('.spam-flagged .spam-check').forEach(function(cb) { cb.checked = true; });
              document.querySelectorAll('tr:not(.spam-flagged) .spam-check').forEach(function(cb) { cb.checked = false; });
            });
          }
          if (none) {
            none.addEventListener('click', function(e) {
              e.preventDefault();
              document.querySelectorAll('.spam-check').forEach(function(cb) { cb.checked = false; });
            });
          }
          if (deleteBtn) {
            deleteBtn.addEventListener('click', function(e) {
              e.preventDefault();
              if (confirm('Are you sure? This cannot be undone.')) {
                document.getElementById('spam-users-form').submit();
              }
            });
          }
        });
      JS
    end
  end
end
