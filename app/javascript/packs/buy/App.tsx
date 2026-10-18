import React, { useEffect, useState } from "react";
import axios from "axios";
import _ from "lodash";
import queryString from "query-string";

import Choice from "./Choice";
import Payment from "./Payment";
import { isRequiresAction } from "./Card";
import PayWhatYouCan from "./PayWhatYouCan";
import { applyTip } from "./Tip";
import { useSettingsContext } from "../menu/Contexts";
import { reportException } from "../../lib/errorReporter";
import type {
  CreditItemResponse,
  CreditBundle,
  CreditPurchaseRequest,
  MenuResponse,
  MenuUser,
  PaymentSubmission,
  RequiresActionResponse,
} from "../../types/api";

type BuyProps = {
  user?: MenuUser;
};

export default function Buy({ user: passedUser }: BuyProps) {
  const {
    bundles: passedBundles,
    enablePayWhatYouCan: passedEnablePayWhatYouCan,
    onRefresh: onComplete,
  } = useSettingsContext();

  const [credits, setCredits] = useState<number | null>(null);
  const [price, setPrice] = useState<number | null>(null);
  const [tip, setTip] = useState<string | null>(null);
  const [breadsPerWeek, setBreadsPerWeek] = useState<number | null>(null);
  const [user, setUser] = useState<MenuUser | undefined>(passedUser);
  const [bundles, setBundles] = useState<CreditBundle[]>(passedBundles || []);
  const [enablePayWhatYouCan, setEnablePayWhatYouCan] = useState(
    !!passedEnablePayWhatYouCan
  );
  const [error, setError] = useState<string | undefined>();
  const [receipt, setReceipt] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // what is the current user?
  useEffect(() => {
    if (user && bundles.length) {
      return;
    }
    const { uid } = queryString.parse(location.search);
    const params = { uid };
    axios
      .get<MenuResponse>("/menu.json", { params })
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
          } else {
            setError("We can't load your user account");
          }
        }
      )
      .catch((error) => {
        console.error("cant load user from menu page", error);
        reportException(error, { kind: "buy_load_user" });
        setError("We can't load your user account");
      });
    // Mount-only: re-running on user/bundles would refetch forever when the
    // menu has no bundles.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleChoose = ({
    credits,
    price,
    breadsPerWeek,
  }: Pick<CreditBundle, "credits" | "price" | "breadsPerWeek">) => {
    setCredits(credits);
    setPrice(price);
    setBreadsPerWeek(breadsPerWeek);
    console.log("selected", credits, "for", "price");
  };

  const handlePriceChanged = (newPrice: number) => {
    if (_.isNumber(newPrice) && newPrice > 0) {
      setPrice(newPrice);
    }
  };
  const totalPrice = applyTip(price, tip);
  // Resolves with the server's response so a card that needs 3D Secure can
  // finish it and pay again (see Card).
  const handlePay = (payment: PaymentSubmission) => {
    const data: CreditPurchaseRequest = {
      uid: user?.hashid || null,
      ...payment,
      price: typeof totalPrice === "number" ? totalPrice : 0,
      credits: credits || 0,
      breadsPerWeek: breadsPerWeek || 0,
    };
    console.log("got card payment", data);
    setSubmitting(true);

    // send the stripe payment to rails to complete purchase
    return axios
      .post<CreditItemResponse | RequiresActionResponse>(
        "/credit_items.json",
        data
      )
      .then(({ data }) => {
        if (isRequiresAction(data)) {
          return data;
        }
        const { creditItem } = data;
        console.log("bought credits", data);

        setReceipt(creditItem.stripeReceiptUrl);

        if (onComplete) {
          onComplete();
        }
      })
      .catch((error) => {
        const { message } = error.response?.data || {};
        console.error("Can't buy credits", error, message);
        const alertWindow = window as Window & {
          alert: (message?: string) => void;
        };
        alertWindow.alert(`Couldn't buy credits: ${message || error}`);
        reportException(error, { kind: "buy_credits" });
      })
      .finally(() => setSubmitting(false));
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

  const stripeApiKey = window.gon?.stripeApiKey;
  const grouped = Object.entries(_.groupBy(bundles, ({ name }) => name));

  return (
    <div className="alert alert-info padding-x-mobile-5px" role="alert">
      <h2 className="mb-3" style={{ fontSize: "1.8rem" }}>
        Buy credits
      </h2>
      {grouped.map(([name, choices]) => {
        return (
          <div key={name} className="text-center">
            {name && name !== "null" && <h6>{name}</h6>}
            {choices.map((choice) => (
              <Choice
                key={choice.credits}
                {...choice}
                onChoose={handleChoose}
              />
            ))}
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
                tip={tip}
                onTip={setTip}
                disabled={submitting}
              />
            </>
          ) : (
            <br />
          )}
          <Payment
            credits={credits}
            price={totalPrice}
            stripeApiKey={stripeApiKey}
            onPay={handlePay}
            submitting={submitting}
            disabled={submitting}
          />
        </>
      )}
    </div>
  );
}
