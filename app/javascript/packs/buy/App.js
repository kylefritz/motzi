import React, { useEffect, useState } from "react";
import axios from 'axios'
import * as Sentry from '@sentry/browser'
import _ from 'lodash'
import queryString from "query-string";

import Choice from './Choice'
import Feedback from './Feedback'
import Payment from './Payment'

// TODO: get prices & stripe key from rails via gon
const weeklyPrice = 172;
const biweeklyPrice = 94;
const stripeApiKey = "pk_test_uAmNwPrPVkEoywEZYTE66AnV00mGp7H2Ud";

export default function Buy() {
  const [choice, setChoice] = useState("weekly")
  const [user, setUser] = useState();
  const [error, setError] = useState();

  const dont = choice === "dont"
  const price = choice === "weekly" ? weeklyPrice : biweeklyPrice;

  // what is the current user?
  useEffect(() => {
    const { uid } = queryString.parse(location.search);
    const params = { uid };
    axios.get("/menu.json", { params }).then(({ data: {user} }) => {
      if(user)
      {
        setUser(user);
        Sentry.configureScope(scope => scope.setUser(user));
      }else{
        setError("We can't load your user account");
      }
    })
    .catch(error => {
      console.error("cant load user from menu page", error);
      Sentry.captureException(error);
      setError("We can't load your user account");
    });
  }, []);


  const handleCardToken = ({ token }) => {
    console.log("card token=", token, { choice, price });

    // send stripe token to rails to complete purchase
    axios.post("/credits.json", { userId: user.id, token: token.id, price, choice })
      .then(({ data }) => {
        console.debug("bought credits", data);

        // this.setState(data)
        // window.scrollTo(0, 0)
      })
      .catch(error => {
        console.error("cant buy credits order", error);
        window.alert("There was a problem buying credits.");
        Sentry.captureException(error);
      });
  };

  const handlePaymentResult = ({ token }) => {
    // with payment request, the price sent to stripe
    console.log("paymentResult token=", token);

    // TODO: send completed payment request to rails
  };

  if(error)
  {
    return <div>{error}</div>
  }

  if (!user) {
    return <div>Loading user for subscription renewal...</div>;
  }

  return (
    <div className="alert alert-info" role="alert">
      <h2 className="mb-3">Renew your subscription</h2>
      <Choice
        name="Weekly"
        price={weeklyPrice}
        onChoose={setChoice}
        defaultChecked={true}
      />
      <Choice name="Bi-Weekly" price={biweeklyPrice} onChoose={setChoice} />
      <h4>Payment amount</h4>
      <p>
        <small>
          These are suggested prices based on the our costs. We want everyone to
          have access to healthy food in this time of crisis and beyond,
          regardless of ability to pay. If you are out of work or otherwise in a
          challenging financial situation please pay what you can or nothing at
          all. If you have the means to pay more we would welcome your support
          in providing for the community and ensuring our continued stability as
          a small business.
        </small>
      </p>
      <Payment
        choice={choice}
        price={price}
        stripeApiKey={stripeApiKey}
        onCardToken={handleCardToken}
        onPaymentResult={handlePaymentResult}
      />
    </div>
  );
}
