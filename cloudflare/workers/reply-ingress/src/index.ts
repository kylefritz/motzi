import PostalMime from "postal-mime";

interface Env {
  MOTZI_URL: string;
  REPLY_WEBHOOK_SECRET: string;
}

interface MotziPayload {
  in_reply_to: string;
  from_email: string;
  from_name?: string;
  body: string;
  message_id?: string;
  subject?: string;
}

export default {
  async email(message: ForwardableEmailMessage, env: Env, ctx: ExecutionContext): Promise<void> {
    try {
      // 1. Verify SPF and DKIM via Authentication-Results
      const authResults = message.headers.get("Authentication-Results") || "";
      const spfPass = /spf=pass/i.test(authResults);
      const dkimPass = /dkim=pass/i.test(authResults);
      if (!spfPass || !dkimPass) {
        message.setReject("SPF or DKIM verification failed");
        return;
      }

      // 2. Parse the email using postal-mime
      const raw = new Response(message.raw);
      const rawBuffer = await raw.arrayBuffer();
      const parsed = await PostalMime.parse(rawBuffer);

      // 3. Extract In-Reply-To — this is how we identify which analysis
      //    the reply belongs to. Our mailer sets a stable Message-ID per
      //    analysis; the replier's client preserves it in In-Reply-To.
      const inReplyTo = parsed.inReplyTo?.trim() || "";
      if (!inReplyTo) {
        message.setReject("Missing In-Reply-To header — not a reply to a known analysis");
        return;
      }

      const fromEmail = parsed.from?.address || "";
      const fromName = parsed.from?.name || "";
      const bodyText = parsed.text || "";

      if (!fromEmail || !bodyText) {
        message.setReject("Missing From address or body");
        return;
      }

      // 4. POST to Motzi
      const payload: MotziPayload = {
        in_reply_to: inReplyTo,
        from_email: fromEmail,
        from_name: fromName,
        body: bodyText,
        message_id: parsed.messageId,
        subject: parsed.subject,
      };

      const response = await fetch(`${env.MOTZI_URL}/reply_ingress`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${env.REPLY_WEBHOOK_SECRET}`,
        },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        let reason = `Motzi rejected the reply (HTTP ${response.status})`;
        try {
          const json = (await response.json()) as { error?: string };
          if (json.error) reason = json.error;
        } catch {
          // ignore parse errors
        }
        message.setReject(reason);
      }
    } catch (err) {
      console.error("reply-ingress error", err);
      message.setReject("Internal worker error — check logs");
    }
  },
};
