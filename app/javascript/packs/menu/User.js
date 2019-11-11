import React from 'react'

export default function User({ user }) {
  return (
    <div className="row mt-5">
      <div className="col">
        <h5 className="text-center">Ordering for</h5>
        <p className="text-center">
          {user.name}
          <small className="ml-3"><a href="/signout" className="text-nowrap">Not you?</a></small>
        </p>

      </div>
      <div className="col">
        <h5 className="text-center">Credits remaining</h5>
        <p className="text-center">{user.credits}</p>
      </div>
      <div className="col">
        <h5 className="text-center">Pickup Day</h5>
        <p className="text-center">{user.isFirstHalf ? "Tuesday" : "Thursday"}</p>
      </div>
    </div>
  );
}
