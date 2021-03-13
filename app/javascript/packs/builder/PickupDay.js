import React, { useRef } from "react";
import styled from "styled-components";
import moment from "moment";
import { useApi } from "./Context";

export function shortDay(pickupAt) {
  const day = moment(pickupAt).format("dddd");
  switch (day) {
    case "Monday":
    case "Tuesday":
    case "Thursday":
    case "Friday":
    case "Sunday":
      return day.replace("day", "");
    case "Wednesday":
      return "Wed";
    case "Saturday":
      return "Sat";
  }
  return day;
}

export function PickupDays({ pickupDays, leadtimeHours }) {
  const inputDeadline = useRef(null);
  const inputPickup = useRef(null);
  const api = useApi();

  function handleSubmit(event) {
    event.preventDefault();
    const pickupAt = inputPickup.current.value;
    const orderDeadlineAt = inputDeadline.current.value;

    if (pickupAt === "" || orderDeadlineAt === "") {
      alert("Set pickup at & deadline at");
      return;
    }
    console.log("pickup", shortDay(pickupAt), pickupAt, "deadline", orderDeadlineAt); // prettier-ignore
    api.pickupDay.add({ pickupAt, orderDeadlineAt }).then(() => {
      // reset form
      inputPickup.current.value = "";
      inputDeadline.current.value = "";
    });
  }
  function handleSetDeadline(event) {
    event.preventDefault();
    const pickup = inputPickup.current.value;
    const deadline = moment(pickup).subtract(
      moment.duration(leadtimeHours || 27, "hours")
    );

    inputDeadline.current.value = deadline
      .toISOString()
      .replace(/:00.000Z/, "");
  }
  return (
    <>
      <h2>Pickup days</h2>
      <ol>
        {pickupDays.map(({ id, deadlineText }) => (
          <li key={id}>
            {deadlineText}{" "}
            <button onClick={() => api.pickupDay.remove(id)}>x</button>
          </li>
        ))}
      </ol>
      <h4>Add</h4>
      <form onSubmit={handleSubmit}>
        <Row>
          <label htmlFor="pickup_at">Pickup at:</label>
          <input id="pickup_at" ref={inputPickup} type="datetime-local" />
        </Row>

        <Row>
          <label htmlFor="order_deadline_at">Order deadline at:</label>
          <input
            id="order_deadline_at"
            ref={inputDeadline}
            type="datetime-local"
          />
          <SmBtn onClick={handleSetDeadline}>
            Apply lead-time {leadtimeHours} hours
          </SmBtn>
          <small>
            From{" "}
            <a href="/admin/settings" target="_blank">
              settings
            </a>
          </small>
        </Row>

        <Row>
          <input type="submit" value="Add pickup day" />
        </Row>
      </form>
    </>
  );
}

const Row = styled.div`
  margin: 1rem 0;
  label {
    margin-right: 1rem;
  }
`;

const SmBtn = styled.button`
  margin-left: 0.25rem;
  font-size: 90%;
`;
