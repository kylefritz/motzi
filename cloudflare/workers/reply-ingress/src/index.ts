import PostalMime from "postal-mime";

interface Env {
  MOTZI_URL: string;
  REPLY_WEBHOOK_SECRET: string;
}

interface MotziPayload {
  analysis_id: string;
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

      // 2. Extract analysis_id from recipient address
      //    Example: reply+analysis-123@thepuff.co
      const match = message.to.match(/reply\+analysis-(\d+)@/i);
      if (!match) {
        message.setReject(`Unknown recipient: ${message.to}`);
        return;
      }
      const analysisId = match[1];

      // 3. Parse the email using postal-mime
      const raw = new Response(message.raw);
      const rawBuffer = await raw.arrayBuffer();
      const parsed = await PostalMime.parse(rawBuffer);

      const fromEmail = parsed.from?.address || "";
      const fromName = parsed.from?.name || "";
      const bodyText = parsed.text || "";

      if (!fromEmail || !bodyText) {
        message.setReject("Missing From address or body");
        return;
      }

      // 4. POST to Motzi
      const payload: MotziPayload = {
        analysis_id: analysisId,
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
