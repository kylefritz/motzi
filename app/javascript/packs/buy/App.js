import React, { useEffect, useState } from "react";
import axios from 'axios'
import * as Sentry from '@sentry/browser'
import _ from 'lodash'
import queryString from "query-string";

import Choice from './Choice'
import Payment from './Payment'

export default function Buy({onComplete, user: passedUser=null}) {
  const [credits, setCredits] = useState();
  const [price, setPrice] = useState();
  const [breadsPerWeek, setBreadsPerWeek] = useState();
  const [user, setUser] = useState(passedUser);
  const [error, setError] = useState();
  const [receipt, setReceipt] = useState();

  // what is the current user?
  useEffect(() => {
    if(user) {
      return;
    }
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

  const handleChoose = ({ credits, price, breadsPerWeek }) => {
    setCredits(credits);
    setPrice(price);
    setBreadsPerWeek(breadsPerWeek)
    console.log("selelcted", credits, "for", "price");
  };

  const handlePriceChanged = (priceString) =>{
    if(priceString){
      const newPrice = parseFloat(priceString);

      if (_.isFinite(newPrice) && newPrice > 0) {
        setPrice(newPrice);
      }
    }
  }

  const handleCardToken = ({ token }) => {
    console.log("card token=", token, { credits, price });

    // send stripe token to rails to complete purchase
    axios.post("/credit_items.json", { uid: user.id, token: token.id, price, credits, breadsPerWeek })
      .then(({ data }) => {
        const {creditItem} = data
        console.log("bought credits", data);

        setReceipt(creditItem.stripeReceiptUrl);

        if(onComplete)
        {
          onComplete(creditItem);
        }
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

  if(receipt)
  {
    return (
      <div className="alert alert-success" role="alert">
        <h2>Thanks for supporting Motzi!!</h2>
        <p className="text-center my-3">
          <a href={receipt} target="blank">
            Here's your receipt
          </a>
        </p>
      </div>
    );
  }

  if(error)
  {
    return <div className="text-center my-3">{error}</div>;
  }

  if (!user) {
    return (
      <h6 className="text-center my-3">
        Loading user for subscription renewal...
      </h6>
    );
  }

  return (
    <div className="alert alert-info padding-x-mobile-5px" role="alert">
      <h2 className="mb-3" style={{fontSize: '1.8rem'}}>Buy credits</h2>

      <h6>6-month</h6>
      <div>
        <Choice breadsPerWeek={1.0} credits={26} price={6.5} total={169} onChoose={handleChoose}/>
        <Choice breadsPerWeek={0.5} credits={13} price={7.0} total={91} onChoose={handleChoose}/>
      </div>

      <h6>3-month</h6>
      <div>
        <Choice breadsPerWeek={1.0} credits={13} price={7.0} total={91} onChoose={handleChoose}/>
        <Choice breadsPerWeek={0.5} credits={6}  price={7.5} total={46} onChoose={handleChoose} />
      </div>
      {
        (credits && price) && (
          <>
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
            <div className="input-group mb-3">
              <div className="input-group-prepend">
                <span className="input-group-text" id="you-pay">You pay $</span>
              </div>
              <input type="number" min="1" max="250" className="form-control" placeholder="Price" aria-label="Price"
                    aria-describedby="you-pay" defaultValue={price} onBlur={(e) => handlePriceChanged(e.target.value)} />
            </div>
            <Payment
              credits={credits}
              price={price}
              stripeApiKey={gon.stripeApiKey}
              onCardToken={handleCardToken}
              onPaymentResult={handlePaymentResult}
            />
          </>
        )
      }
    </div>
  );
}
