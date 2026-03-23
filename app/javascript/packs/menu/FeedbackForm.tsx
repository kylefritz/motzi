import React, { useState } from "react";

type FeedbackFormState = "link" | "form" | "success" | "error";

export default function FeedbackForm() {
  const [state, setState] = useState<FeedbackFormState>("link");
  const [message, setMessage] = useState("");
  const [email, setEmail] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);

    try {
      const response = await fetch("/api/feedbacks", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          feedback: {
            source: "menu",
            message,
            email: email || undefined,
            url: window.location.href,
          },
        }),
      });

      if (response.ok) {
        setState("success");
      } else {
        setState("error");
      }
    } catch {
      setState("error");
    } finally {
      setSubmitting(false);
    }
  };

  if (state === "link") {
    return (
      <div className="text-center mt-2 mb-3">
        <small>
          <a
            href="#"
            onClick={(e) => {
              e.preventDefault();
              setState("form");
            }}
          >
            Share feedback
          </a>
        </small>
      </div>
    );
  }

  if (state === "success") {
    return (
      <div className="alert alert-success text-center mt-2 mb-3">
        Thanks for the feedback!
      </div>
    );
  }

  if (state === "error") {
    return (
      <div className="alert alert-warning text-center mt-2 mb-3">
        Something went wrong.{" "}
        <a
          href="#"
          onClick={(e) => {
            e.preventDefault();
            setState("form");
          }}
        >
          Try again
        </a>
      </div>
    );
  }

  return (
    <div className="mt-2 mb-3">
      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <textarea
            className="form-control"
            rows={3}
            placeholder="What's on your mind?"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            required
          />
        </div>
        <div className="form-group">
          <input
            type="email"
            className="form-control"
            placeholder="Your email (optional)"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
        </div>
        <button
          type="submit"
          className="btn btn-primary btn-block"
          disabled={submitting}
        >
          {submitting ? "Sending..." : "Send Feedback"}
        </button>
        <div className="text-center mt-1">
          <small>
            <a
              href="#"
              onClick={(e) => {
                e.preventDefault();
                setState("link");
                setMessage("");
                setEmail("");
              }}
            >
              Cancel
            </a>
          </small>
        </div>
      </form>
    </div>
  );
}
