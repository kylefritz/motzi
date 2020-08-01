import React, { useEffect, useState } from "react";
import axios from "axios";
import * as Sentry from "@sentry/browser";
import _ from "lodash";
import queryString from "query-string";

import Choice from "./Choice";
import Payment from "./Payment";
import PayWhatYouCan from "./PayWhatYouCan";

export default function Buy({
  onComplete,
  user: passedUser = null,
  bundles: passedBundles = [],
  enablePayWhatYouCan: passedEnablePayWhatYouCan,
}) {
  const [credits, setCredits] = useState();
  const [price, setPrice] = useState();
  const [breadsPerWeek, setBreadsPerWeek] = useState();
  const [user, setUser] = useState(passedUser);
  const [bundles, setBundles] = useState(passedBundles);
  const [enablePayWhatYouCan, setEnablePayWhatYouCan] = useState(
    passedEnablePayWhatYouCan
  );
  const [error, setError] = useState();
  const [receipt, setReceipt] = useState();
  const [submitting, setSubmitting] = useState(false);

  // what is the current user?
  useEffect(() => {
    if (user && bundles.length) {
      return;
    }
    const { uid } = queryString.parse(location.search);
    const params = { uid };
    axios
      .get("/menu.json", { params })
      .then(
        ({
          data: {
            user,
            bundles: nextBundles,
            menu: { enablePayWhatYouCan: nextEnablePayWhatYouCan },
          },
        }) => {
          if (user) {
            setUser(user);
            setBundles(nextBundles);
            setEnablePayWhatYouCan(nextEnablePayWhatYouCan);
            Sentry.configureScope((scope) => scope.setUser(user));
          } else {
            setError("We can't load your user account");
          }
        }
      )
      .catch((error) => {
        console.error("cant load user from menu page", error);
        Sentry.captureException(error);
        setError("We can't load your user account");
      });
  }, []);

  const handleChoose = ({ credits, price, breadsPerWeek }) => {
    setCredits(credits);
    setPrice(price);
    setBreadsPerWeek(breadsPerWeek);
    console.log("selected", credits, "for", "price");
  };

  const handlePriceChanged = (newPrice) => {
    if (_.isNumber(newPrice) && newPrice > 0) {
      setPrice(newPrice);
    }
  };

  const handleCardToken = ({ token }) => {
    console.log("card token=", token, { credits, price });
    setSubmitting(true);

    // send stripe token to rails to complete purchase
    axios
      .post("/credit_items.json", {
        uid: user.hashid,
        token: token.id,
        price,
        credits,
        breadsPerWeek,
      })
      .then(({ data }) => {
        const { creditItem } = data;
        console.log("bought credits", data);

        setReceipt(creditItem.stripeReceiptUrl);

        if (onComplete) {
          onComplete(creditItem);
        }
      })
      .catch((error) => {
        console.error("cant buy credits order", error);
        window.alert("There was a problem buying credits.");
        Sentry.captureException(error);
      })
      .then(() => setSubmitting(false));
  };

  const handlePaymentResult = ({ token }) => {
    // with payment request, the price sent to stripe
    console.error("paymentResult token=", token);

    // TODO: send completed payment request to rails
  };

  if (receipt) {
    return (
      <div className="alert alert-success" role="alert">
        <h2>Thanks for your support!!</h2>
        <p className="text-center my-3">
          <a href={receipt} target="blank">
            Here's your receipt
          </a>
        </p>
      </div>
    );
  }

  if (error) {
    return <div className="text-center my-3">{error}</div>;
  }

  if (!user) {
    return (
      <h6 className="text-center my-3">
        Loading user for subscription renewal...
      </h6>
    );
  }

  const grouped = Object.entries(_.groupBy(bundles, ({ name }) => name));

  return (
    <div className="alert alert-info padding-x-mobile-5px" role="alert">
      <h2 className="mb-3" style={{ fontSize: "1.8rem" }}>
        Buy credits
      </h2>
      {grouped.map(([name, choices]) => {
        return (
          <div key={name}>
            {name && name !== "null" && <h6>{name}</h6>}
            <div className="text-center">
              {choices.map((choice) => (
                <Choice
                  key={choice.credits}
                  {...choice}
                  onChoose={handleChoose}
                />
              ))}
            </div>
          </div>
        );
      })}
      {credits && price && (
        <>
          {enablePayWhatYouCan ? (
            <>
              <h4>Payment amount</h4>
              <PayWhatYouCan
                price={price}
                onPricedChanged={handlePriceChanged}
              />
            </>
          ) : (
            <br />
          )}
          <Payment
            credits={credits}
            price={price}
            stripeApiKey={gon.stripeApiKey}
            onCardToken={handleCardToken}
            onPaymentResult={handlePaymentResult}
            submitting={submitting}
          />
        </>
      )}
    </div>
  );
}
