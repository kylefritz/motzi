class SpamDetector
  MODEL = "claude-haiku-4-5"

  # Claude's reply was cut off or isn't the JSON we asked for. Raised instead
  # of returning [], which the admin page would show as "0 spam accounts".
  class UnreadableResponse < StandardError; end

  def initialize(&on_progress)
    @on_progress = on_progress || ->(_msg) { }
  end

  def scan
    candidates = load_candidates
    @on_progress.call("Found #{candidates.size} candidate accounts")
    return [] if candidates.empty?

    user_message = build_user_message(candidates)
    @on_progress.call("Sending #{candidates.size} accounts to Claude (#{MODEL})...")
    response = call_claude(user_message)
    @on_progress.call("Parsing results...")

    # A reply that ran out of tokens can still end in a complete-looking array
    # that lists only some of the spam.
    if response[:stop_reason].to_s == "max_tokens"
      raise UnreadableResponse, "Claude's reply was cut off at the token limit (#{candidates.size} accounts sent)"
    end

    parse_spam_ids(response[:text])
  end

  private

  def load_candidates
    User.where.missing(:orders, :credit_items) # anyone with either is a member
        .where("sign_in_count <= 1")
        .where.not(email: [ User::MAYA_EMAIL, User::RUSSELL_EMAIL ].compact)
        .where.not(id: User::SYSTEM_ID) # exclude system user
        .order(:created_at)
  end

  def build_user_message(candidates)
    lines = [ "# User accounts to review (#{candidates.size} total)", "" ]
    lines << "ID | Name | Email | Sign-ins | Created"
    lines << "---|------|-------|----------|--------"
    candidates.each do |u|
      lines << "#{u.id} | #{u.first_name} #{u.last_name} | #{u.email} | #{u.sign_in_count} | #{u.created_at.to_date}"
    end
    lines.join("\n")
  end

  def call_claude(user_message)
    system_prompt = File.read(Rails.root.join("app/prompts/spam_detection.txt"))
    client = Anthropic::Client.new
    response = client.messages.create(
      model: MODEL,
      max_tokens: 4096,
      system_: system_prompt,
      messages: [ { role: "user", content: user_message } ]
    )

    text = response.content.filter_map do |block|
      block.text if block.respond_to?(:text)
    end.join("\n")

    { text: text, stop_reason: response.stop_reason }
  end

  # No "[" at all means Claude answered in prose that nothing looks like spam.
  # An array that was started but can't be parsed is a broken reply.
  def parse_spam_ids(text)
    return [] unless text.include?("[")

    json = text[/\[.*\]/m]
    raise UnreadableResponse, "Claude's reply has a list that was never finished" unless json

    JSON.parse(json, symbolize_names: true)
  rescue JSON::ParserError => e
    raise UnreadableResponse, "Claude's reply isn't valid JSON: #{e.message.first(200)}"
  end
end
