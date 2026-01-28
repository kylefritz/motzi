import React, { useRef, useEffect, useState } from "react";
import styled from "styled-components";
import moment from "moment";
import { useApi } from "../Context";
import type { AdminPickupDay } from "../../../types/api";

export function shortDay(pickupAt: string) {
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

type PickupDaysPanelProps = {
  pickupDays: AdminPickupDay[];
  leadtimeHours: number | null;
};

export default function PickupDaysPanel({
  pickupDays,
  leadtimeHours,
}: PickupDaysPanelProps) {
  const inputDeadline = useRef<HTMLInputElement | null>(null);
  const inputPickup = useRef<HTMLInputElement | null>(null);
  const api = useApi();

  function handleSubmit(event: React.FormEvent) {
    event.preventDefault();
    const pickupAt = inputPickup.current?.value || "";
    const orderDeadlineAt = inputDeadline.current?.value || "";

    if (pickupAt === "" || orderDeadlineAt === "") {
      alert("Set pickup at & deadline at");
      return;
    }
    console.log("pickup", shortDay(pickupAt), pickupAt, "deadline", orderDeadlineAt); // prettier-ignore
    api.pickupDay.add({ pickupAt, orderDeadlineAt }).then(() => {
      // reset form
      if (inputPickup.current) {
        inputPickup.current.value = "";
      }
      if (inputDeadline.current) {
        inputDeadline.current.value = "";
      }
    });
  }
  function handleSetDeadline(event: React.MouseEvent<HTMLButtonElement>) {
    event.preventDefault();
    const pickup = inputPickup.current?.value || "";
    const deadline = moment(pickup).subtract(
      moment.duration(leadtimeHours || 27, "hours")
    );

    if (inputDeadline.current) {
      inputDeadline.current.value = deadline
        .toISOString()
        .replace(/:00.000Z/, "");
    }
  }
  return (
    <>
      <h2>Pickup days</h2>
      <List>
        {pickupDays.map((pickupDay) => (
          <ListItem key={pickupDay.id}>
            <EditablePickupDay
              pickupDay={pickupDay}
              onRemove={() => api.pickupDay.remove(pickupDay.id)}
              onSave={(payload) => api.pickupDay.update(pickupDay.id, payload)}
            />
          </ListItem>
        ))}
      </List>
      <SectionTitle>Add</SectionTitle>
      <form onSubmit={handleSubmit}>
        <FieldRow>
          <label htmlFor="pickup_at">Pickup at:</label>
          <input id="pickup_at" ref={inputPickup} type="datetime-local" />
        </FieldRow>

        <FieldRow>
          <label htmlFor="order_deadline_at">Order deadline at:</label>
          <input
            id="order_deadline_at"
            ref={inputDeadline}
            type="datetime-local"
          />
          <SmBtn type="button" onClick={handleSetDeadline}>
            Apply lead-time {leadtimeHours} hours
          </SmBtn>
          <small>
            From{" "}
            <a href="/admin/settings" target="_blank" rel="noreferrer">
              settings
            </a>
          </small>
        </FieldRow>

        <Row>
          <PrimaryBtn type="submit">Add pickup day</PrimaryBtn>
        </Row>
      </form>
    </>
  );
}

type EditablePickupDayProps = {
  pickupDay: AdminPickupDay;
  onRemove: () => void;
  onSave: (payload: { pickupAt: string; orderDeadlineAt: string }) => Promise<unknown>;
};

function formatDateTimeLocal(value: string) {
  return moment(value).format("YYYY-MM-DDTHH:mm");
}

function EditablePickupDay({
  pickupDay,
  onRemove,
  onSave,
}: EditablePickupDayProps) {
  const initialPickupAt = formatDateTimeLocal(pickupDay.pickupAt);
  const initialDeadline = formatDateTimeLocal(pickupDay.orderDeadlineAt);
  const [pickupAtValue, setPickupAtValue] = useState(initialPickupAt);
  const [deadlineValue, setDeadlineValue] = useState(initialDeadline);
  const [isEditing, setIsEditing] = useState(false);
  const isDirty =
    pickupAtValue !== initialPickupAt || deadlineValue !== initialDeadline;

  useEffect(() => {
    setPickupAtValue(initialPickupAt);
    setDeadlineValue(initialDeadline);
    setIsEditing(false);
  }, [initialPickupAt, initialDeadline]);

  function handleSave(event: React.MouseEvent<HTMLButtonElement>) {
    event.preventDefault();
    if (!isDirty) {
      return;
    }
    onSave({
      pickupAt: pickupAtValue,
      orderDeadlineAt: deadlineValue,
    }).then(() => {
      setIsEditing(false);
    });
  }

  function handleCancel(event: React.MouseEvent<HTMLButtonElement>) {
    event.preventDefault();
    setPickupAtValue(initialPickupAt);
    setDeadlineValue(initialDeadline);
    setIsEditing(false);
  }

  function handleEdit(event: React.MouseEvent<HTMLButtonElement>) {
    event.preventDefault();
    setIsEditing(true);
  }

  return (
    <>
      {!isEditing ? (
        <RowInline>
          <strong>{pickupDay.deadlineText}</strong>
          <ActionRow>
            <SmBtn type="button" onClick={handleEdit}>
              Edit
            </SmBtn>
            <DeleteBtn type="button" onClick={onRemove}>
              x
            </DeleteBtn>
          </ActionRow>
        </RowInline>
      ) : (
        <EditPanel>
          <FieldRow>
            <label htmlFor={`pickup_day_${pickupDay.id}_pickup_at`}>
              Pickup at:
            </label>
            <input
              id={`pickup_day_${pickupDay.id}_pickup_at`}
              type="datetime-local"
              value={pickupAtValue}
              onChange={(event) => setPickupAtValue(event.target.value)}
            />
          </FieldRow>
          <FieldRow>
            <label htmlFor={`pickup_day_${pickupDay.id}_order_deadline_at`}>
              Order deadline at:
            </label>
            <input
              id={`pickup_day_${pickupDay.id}_order_deadline_at`}
              type="datetime-local"
              value={deadlineValue}
              onChange={(event) => setDeadlineValue(event.target.value)}
            />
          </FieldRow>
          <Row>
            <PrimaryBtn type="button" onClick={handleSave} disabled={!isDirty}>
              Save
            </PrimaryBtn>
            <SecondaryBtn type="button" onClick={handleCancel}>
              Cancel
            </SecondaryBtn>
            <DeleteBtn type="button" onClick={onRemove}>
              x
            </DeleteBtn>
          </Row>
        </EditPanel>
      )}
    </>
  );
}

const Row = styled.div`
  margin: 1rem 0;
  label {
    margin-right: 1rem;
  }
`;

const FieldRow = styled(Row)`
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin: 0.65rem 0;

  label {
    min-width: 150px;
  }
  input {
    min-width: 240px;
  }
`;

const RowInline = styled(Row)`
  display: flex;
  align-items: center;
  gap: 0.4rem;
  padding: 0.35rem 0;

  strong {
    font-weight: 600;
  }
`;

const ActionRow = styled.div`
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  margin-left: 0.25rem;
`;

const DeleteBtn = styled.button`
  padding: 0 0.5rem;
  border: 1px solid #d0d0d0;
  background: #fff;
  border-radius: 4px;
  font-weight: 600;
`;

const SmBtn = styled.button`
  padding: 0.2rem 0.6rem;
  font-size: 90%;
  border: 1px solid #d0d0d0;
  background: #f8f8f8;
  border-radius: 4px;
  color: #222;
`;

const PrimaryBtn = styled(SmBtn)`
  background: #3f3a80;
  color: #fff;
  border-color: #3f3a80;
  &:disabled {
    background: #d6d6e6;
    border-color: #d6d6e6;
    color: #707070;
    cursor: not-allowed;
    opacity: 0.9;
  }
`;

const SecondaryBtn = styled(SmBtn)`
  background: #fff;
`;

const List = styled.ol`
  margin: 0;
  padding-left: 1.25rem;
`;

const ListItem = styled.li`
  margin: 0.6rem 0 1rem;
`;

const SectionTitle = styled.h4`
  margin-top: 1.5rem;
`;

const EditPanel = styled.div`
  padding: 0.5rem 0 0.25rem;
  border-left: 2px solid #ececec;
  padding-left: 0.75rem;
`;
