import React from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import _ from "lodash";
import type { AdminCreditItemRequest } from "../../types/api";

export default function App() {
  const memoRef = React.createRef<HTMLInputElement>();
  const quantityRef = React.createRef<HTMLInputElement>();
  const weeksRef = React.createRef<HTMLInputElement>();
  const userId = parseInt(
    _.get(window.location?.pathname.match(/users\/(.*)/), 1),
    10
  );

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault();
    const credit: AdminCreditItemRequest = {
      memo: memoRef.current?.value || "",
      quantity: Number(quantityRef.current?.value || 0),
      goodForWeeks: Number(weeksRef.current?.value || 0),
      userId,
    };
    console.info(credit);
    axios
      .post(`/admin/credit_items.json`, credit)
      .then(({ data }) => {
        // reload page
        document.location = document.location;
      })
      .catch((error) => {
        console.error("couldn't create credit", error);
        Sentry.captureException(error);
        alert("Couldn't create credit?!");
      });
  };

  return (
    <details>
      <summary>Add credit</summary>
      <form onSubmit={handleSubmit.bind(this)}>
        <fieldset>
          <ol>
            <li className="string input optional stringish">
              <label htmlFor="credit_entry_memo" className="label">
                Memo
              </label>
              <input type="text" ref={memoRef} />
            </li>

            <li className="number input optional numeric stringish">
              <label htmlFor="credit_entry_quantity" className="label">
                Quantity
              </label>
              <input step="any" type="number" ref={quantityRef} />
            </li>

            <li className="number input optional numeric stringish">
              <label htmlFor="credit_entry_good_for_weeks" className="label">
                Good for weeks
              </label>
              <input step="any" type="number" ref={weeksRef} />
            </li>
          </ol>
        </fieldset>
        <fieldset>
          <ol>
            <li
              className="action input_action "
              id="credit_entry_submit_action"
            >
              <input type="submit" value="Add credit" />
            </li>
          </ol>
        </fieldset>
      </form>
    </details>
  );
}
