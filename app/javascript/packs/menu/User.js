import React from 'react'

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

export default function User({ user }) {
  // TODO: add weeks remaining
  // <div className="col">
  //   <h5 className="text-center">Weeks remaining</h5>
  //   <p className="text-center"></p>
  // </div>
  return (
    <div className="row mt-5">
      <div className="col">
        <h5 className="text-center">Ordering for</h5>
        <p className="text-center">
          {user.name}
          <small className="ml-2"><a href="/signout" className="text-nowrap">Not you?</a></small>
        </p>
      </div>
      <div className="col">
        <h5 className="text-center">Ordering frequency</h5>
        <p className="text-center" title={user.breadsPerWeek}>
          {humanizeBreadsPerWeek(user.breadsPerWeek)}
        </p>
      </div>
      <div className="col">
        <h5 className="text-center">Credits remaining</h5>
        <p className="text-center">{user.credits}</p>
      </div>
      <div className="col">
        <h5 className="text-center">Pickup Day</h5>
        <p className="text-center">{user.tuesdayPickup ? "Tuesday" : "Thursday"}</p>
      </div>
    </div>
  );
}
