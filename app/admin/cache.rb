ActiveAdmin.register_page 'Cache' do
  menu parent: 'Advanced', priority: 1

  TTL_OPTIONS = [
    ['1 hour', 1.hour.to_i],
    ['6 hours', 6.hours.to_i],
    ['1 day', 1.day.to_i],
    ['7 days', 7.days.to_i],
    ['30 days', 30.days.to_i],
    ['Never', 0]
  ].freeze

  # Add a new cache entry
  page_action :create_entry, method: :post do
    key = params[:cache_key].to_s.strip
    value = params[:cache_value].to_s
    ttl = params[:cache_ttl].to_i

    if key.blank?
      redirect_to admin_cache_path, alert: 'Key cannot be blank.'
      return
    end

    opts = ttl.positive? ? { expires_in: ttl.seconds } : {}
    Rails.cache.write(key, value, **opts)
    redirect_to admin_cache_path, notice: "Cached '#{key}' successfully."
  end

  # Delete a single cache entry
  page_action :delete_entry, method: :post do
    key = params[:cache_key].to_s
    Rails.cache.delete(key)
    redirect_to admin_cache_path, notice: "Deleted '#{key}'."
  end

  # Clear entire cache
  page_action :clear_all, method: :post do
    Rails.cache.clear
    redirect_to admin_cache_path, notice: 'Cache cleared.'
  end

  content title: 'Cache' do
    entries = if defined?(SolidCache::Entry)
                SolidCache::Entry.order(created_at: :desc).page(params[:page]).per(25)
              else
                SolidCache::Entry.none.page(1).per(25)
              end

    max_age = Rails.cache.try(:max_age) || 30.days

    # Add entry form
    div class: 'cache-toolbar' do
      h4 'Add Entry'
      form_for :cache, url: admin_cache_create_entry_path, method: :post, html: { class: 'cache-add-form' } do |_f|
        div class: 'cache-form-fields' do
          label_tag :cache_key, 'Key'
          text_field_tag :cache_key, nil, placeholder: 'my/cache/key', class: 'cache-input'

          label_tag :cache_value, 'Value'
          text_area_tag :cache_value, nil, placeholder: 'Value...', rows: 2, class: 'cache-input cache-textarea'

          label_tag :cache_ttl, 'TTL'
          select_tag :cache_ttl, options_for_select(TTL_OPTIONS), class: 'cache-input'

          submit_tag 'Add', class: 'cache-submit-btn'
        end
      end
    end

    # Toolbar
    div class: 'cache-toolbar' do
      div class: 'cache-toolbar-left' do
        span "#{entries.total_count} entries", class: 'cache-count'
      end
      div class: 'cache-toolbar-right' do
        text_node button_to('Clear All Cache',
                           admin_cache_clear_all_path,
                           method: :post,
                           class: 'cache-clear-btn',
                           data: { confirm: 'This will flush ALL cached data including framework caches. Are you sure?' })
      end
    end

    if entries.any?
      table class: 'cache-table' do
        thead do
          tr do
            th 'Key'
            th 'Value'
            th 'Size'
            th 'Created'
            th 'Est. Expiry'
            th ''
          end
        end
        tbody do
          entries.each do |entry|
            display_key = entry.key

            # Read value through cache API for proper deserialization
            cached_value = begin
              val = Rails.cache.read(display_key)
              val.nil? ? '(nil)' : val.inspect.truncate(100)
            rescue => e
              "(error: #{e.message.truncate(50)})"
            end

            estimated_expiry = entry.created_at ? entry.created_at + max_age : nil

            tr do
              td class: 'cache-key' do
                code display_key
              end
              td class: 'cache-value' do
                span cached_value
              end
              td number_to_human_size(entry.byte_size)
              td entry.created_at ? time_ago_in_words(entry.created_at) + ' ago' : '—'
              td do
                if estimated_expiry
                  if estimated_expiry > Time.current
                    span "~#{time_ago_in_words(estimated_expiry)}", class: 'cache-expires'
                  else
                    span 'Expired', class: 'cache-expired'
                  end
                else
                  span '—'
                end
              end
              td do
                text_node button_to('Delete',
                                   admin_cache_delete_entry_path(cache_key: display_key),
                                   method: :post,
                                   class: 'cache-delete-btn',
                                   data: { confirm: "Delete '#{display_key}'?" })
              end
            end
          end
        end
      end

      # Pagination
      div class: 'cache-pagination' do
        text_node paginate(entries)
      end
    else
      para 'No cache entries found.', class: 'cache-empty'
    end
  end
end
