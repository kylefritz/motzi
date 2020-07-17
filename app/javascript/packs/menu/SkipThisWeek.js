import React from "react";

export default function SkipThisWeek({
  onSkip,
  description = "I'd like to skip this week, please credit me for a future week (limit 3 per 6 month period).",
}) {
  return (
    <>
      <h5>Skip this week?</h5>
      <div className="row">
        <div className="col-6 mb-3">
          <div className="mb-2">
            <button
              type="button"
              className="btn btn-sm btn-dark"
              onClick={onSkip}
            >
              Skip Now
            </button>
          </div>
          <div style={{ lineHeight: "normal" }}>
            <small>
              {description} <em>Removes any selected items from order.</em>
            </small>
          </div>
        </div>
      </div>
    </>
  );
}
