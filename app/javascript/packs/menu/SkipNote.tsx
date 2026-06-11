import React from "react";

export default function SkipNote() {
  return (
    <>
      <h5>Not ordering this week?</h5>
      <div className="row">
        <div className="col-6 mb-3">
          <div style={{ lineHeight: "normal" }}>
            <small>
              Don't place an order and your credits will carry over
              automatically.
              <br />
              There's no longer a required "skip" option.
            </small>
          </div>
        </div>
      </div>
    </>
  );
}
