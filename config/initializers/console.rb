# https://github.com/paper-trail-gem/paper_trail/wiki/Setting-whodunnit-in-the-rails-console
Rails.application.configure do
  console do
    PaperTrail.request.whodunnit = ->() {
      @paper_trail_whodunnit ||= (
        kyle_id   = User.kyle&.id
        adrian_id = User.adrian&.id

        user_id = nil
        until user_id.present? do
          print "Attribute change to which user_id [kyle: #{kyle_id} adrian: #{adrian_id}]? "
          user_id = gets.chomp
        end
        puts "Papertrail user_id: #{user_id}"
        user_id
      )
    }
  end
end
