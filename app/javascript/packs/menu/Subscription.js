import React, { useState } from "react";
import BuyCredits from "../buy/App";

export const humanizeBreadsPerWeek = (perWeek) => {
  if (perWeek === 0.5) {
    return "Every other week";
  }
  if (perWeek === 1.0) {
    return "Every week";
  }
  if (perWeek === 2.0) {
    return "Two breads per week";
  }
  if (perWeek === 3.0) {
    return "Three breads per week";
  }
  return `${perWeek} breads per week`;
};

export default function Subscription({ user, onRefreshUser, bundles }) {
  const [showBuy, setShowBuy] = useState(false);

  return (
    <>
      <div className="row">
        <div className="col">
          <h5 className="text-center">Subscriber</h5>
          <div className="text-center mb-2">
            <div className="subscriber-info">{user.name}</div>
            <div>
              <small className="ml-2">
                <a href="/signout" className="text-nowrap">
                  Not you?
                </a>
              </small>
            </div>
          </div>
        </div>
        {user.subscriber && (
          <>
            <div className="col">
              <h5 className="text-center">Credits</h5>
              <div className="text-center">
                <div className="subscriber-info">{user.credits}</div>
                {onRefreshUser && (
                  <button
                    type="button"
                    className="btn btn-sm btn-link text-nowrap"
                    style={{ fontSize: "80%" }}
                    onClick={() => setShowBuy(!showBuy)}
                  >
                    Buy more
                  </button>
                )}
              </div>
            </div>
          </>
        )}
      </div>
      {showBuy && (
        <BuyCredits onComplete={onRefreshUser} {...{ user, bundles }} />
      )}
    </>
  );
}
