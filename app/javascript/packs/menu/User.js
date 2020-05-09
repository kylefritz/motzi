import React from "react";

export default function User({ user, deadlineDay }) {
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
          <h5 className="text-center">Order By</h5>
          <p className="text-center">{deadlineDay} Midnight</p>
        </div>
      </div>
    </>
  );
}
