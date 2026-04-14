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
  async email(
    message: ForwardableEmailMessage,
    env: Env,
    ctx: ExecutionContext,
  ): Promise<void> {
    try {
      // Cloudflare stamps its own auth verdict into `ARC-Authentication-Results`
      // with authserv-id `mx.cloudflare.net`. The plain `Authentication-Results`
      // header, if present, was added by some upstream hop (e.g. the sender's
      // own outbound gateway) and can't be trusted here. Prefer CF's header and
      // only fall back to the generic one so self-hosted test setups keep
      // working.
      //
      // Accept if DMARC, SPF, or DKIM passed — forwarding (e.g. custom-domain
      // relays) often breaks SPF while preserving DKIM, and DMARC alignment is
      // itself a stronger signal than either alone.
      const authResults =
        message.headers.get("ARC-Authentication-Results") ||
        message.headers.get("Authentication-Results") ||
        "";
      const spfPass = /\bspf=pass\b/i.test(authResults);
      const dkimPass = /\bdkim=pass\b/i.test(authResults);
      const dmarcPass = /\bdmarc=pass\b/i.test(authResults);
      if (!spfPass && !dkimPass && !dmarcPass) {
        const snippet = authResults.slice(0, 200).replace(/\s+/g, " ");
        message.setReject(
          `SPF, DKIM, and DMARC verification failed${snippet ? ` (${snippet})` : ""}`,
        );
        return;
      }

      const rawBuffer = await new Response(message.raw).arrayBuffer();
      const parsed = await PostalMime.parse(rawBuffer);

      const inReplyTo = parsed.inReplyTo?.trim() || "";
      const fromEmail = parsed.from?.address || "";
      const bodyText = parsed.text || "";

      if (!inReplyTo) {
        message.setReject(
          "Missing In-Reply-To — not a reply to a known analysis",
        );
        return;
      }
      if (!fromEmail || !bodyText) {
        message.setReject("Missing From address or body");
        return;
      }

      const payload: MotziPayload = {
        in_reply_to: inReplyTo,
        from_email: fromEmail,
        from_name: parsed.from?.name || "",
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
        signal: AbortSignal.timeout(10_000),
      });

      if (!response.ok) {
        let reason = `Motzi rejected the reply (HTTP ${response.status})`;
        try {
          const json = (await response.json()) as { error?: string };
          if (json.error) reason = json.error;
        } catch {
          /* non-JSON body */
        }
        message.setReject(reason);
      }
    } catch (err) {
      console.error("reply-ingress error", err);
      message.setReject("Internal worker error — check logs");
    }
  },
};
