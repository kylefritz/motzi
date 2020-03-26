import React, {useState} from 'react'
import BuyCredits from "../buy/App";

export const humanizeBreadsPerWeek = (perWeek) => {
  if (perWeek == 0.5) {
    return "Every other week";
  }
  if (perWeek == 1.0) {
    return "Every week";
  }
  if (perWeek == 2.0) {
    return "Two breads per week";
  }
  if (perWeek == 3.0) {
    return "Three breads per week";
  }
  return `${perWeek} breads per week`;
}

export default function User({ user, onRefreshUser }) {
  const [showBuy, setShowBuy] = useState(false)

  // TODO: add weeks remaining
  // <div className="col">
  //   <h5 className="text-center">Weeks remaining</h5>
  //   <p className="text-center"></p>
  // </div>
  return (
    <>
      <div className="row mt-5">
        <div className="col">
          <h5 className="text-center">Ordering for</h5>
          <div className="text-center mb-2">
            <div>{user.name}</div>
            <div>
              <small className="ml-2">
                <a href="/signout" className="text-nowrap">
                  Not you?
                </a>
              </small>
            </div>
          </div>
        </div>
        <div className="col">
          <h5 className="text-center">Ordering frequency</h5>
          <p className="text-center" title={user.breadsPerWeek}>
            {humanizeBreadsPerWeek(user.breadsPerWeek)}
          </p>
        </div>
        <div className="col">
          <h5 className="text-center">Credits remaining</h5>
          <p className="text-center">
            {user.credits}
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
          </p>
        </div>
        <div className="col">
          <h5 className="text-center">Pickup Day</h5>
          <p className="text-center">
            {user.pickupDay}
          </p>
        </div>
      </div>
      {showBuy && <BuyCredits onComplete={onRefreshUser} user={user} />}
    </>
  );
}
