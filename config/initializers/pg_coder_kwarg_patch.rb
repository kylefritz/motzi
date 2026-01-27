# frozen_string_literal: true

# Avoid PG::Coder.new(hash) deprecation warnings from Rails 6.1 + pg 1.5.
ActiveSupport.on_load(:active_record) do
  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter
        private

        def update_typemap_for_default_timezone
          return unless @default_timezone != ActiveRecord::Base.default_timezone && @timestamp_decoder

          decoder_class = ActiveRecord::Base.default_timezone == :utc ?
            PG::TextDecoder::TimestampUtc :
            PG::TextDecoder::TimestampWithoutTimeZone

          decoder_kwargs = @timestamp_decoder.to_h.transform_keys(&:to_sym)
          @timestamp_decoder = decoder_class.new(**decoder_kwargs)
          @connection.type_map_for_results.add_coder(@timestamp_decoder)
          @default_timezone = ActiveRecord::Base.default_timezone
        end
      end
    end
  end
end
