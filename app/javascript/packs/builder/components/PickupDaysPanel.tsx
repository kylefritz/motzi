import React, { useRef, useEffect, useState } from "react";
import styled from "styled-components";
import moment from "moment";
import { useApi } from "../Context";
import type { AdminPickupDay } from "../../../types/api";
import { Button } from "./ui/Button";
import { Panel, PanelBody, PanelHeader } from "./ui/Panel";
import { ControlInput } from "./ui/FormControls";

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

function parsePickupDayText(text: string) {
  const match = text.match(/^(.*?)\s*\(order by\s*(.*?)\)\s*$/i);
  if (!match) {
    return { pickupLabel: text, orderByLabel: null };
  }
  return { pickupLabel: match[1], orderByLabel: match[2] };
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
  const handleRemove = (pickupDayId: number) => {
    const confirmed = window.confirm("Delete this pickup day?");
    if (!confirmed) {
      return;
    }
    api.pickupDay.remove(pickupDayId);
  };

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
      <List role="list">
        {pickupDays.map((pickupDay) => (
          <PickupDayCard key={pickupDay.id}>
            <EditablePickupDay
              pickupDay={pickupDay}
              onRemove={() => handleRemove(pickupDay.id)}
              onSave={(payload) => api.pickupDay.update(pickupDay.id, payload)}
            />
          </PickupDayCard>
        ))}
      </List>
      <AddPanel>
        <PanelHeader>Add pickup day</PanelHeader>
        <PanelBody>
          <form onSubmit={handleSubmit}>
            <InlineEditor>
              <FieldStack>
                <FieldLabel htmlFor="pickup_at">Pickup at:</FieldLabel>
                <DateInput
                  id="pickup_at"
                  ref={inputPickup}
                  type="datetime-local"
                />
              </FieldStack>

              <FieldStack>
                <FieldLabel htmlFor="order_deadline_at">
                  Order deadline at:
                </FieldLabel>
                <DateInput
                  id="order_deadline_at"
                  ref={inputDeadline}
                  type="datetime-local"
                />
              </FieldStack>
            </InlineEditor>

            <LeadtimeActions>
              <Button type="button" size="sm" variant="secondary" onClick={handleSetDeadline}>
                Apply lead-time {leadtimeHours} hours
              </Button>
              <small>
                From{" "}
                <a href="/admin/settings" target="_blank" rel="noreferrer">
                  settings
                </a>
              </small>
            </LeadtimeActions>

            <ButtonRow>
              <Button type="submit">Add pickup day</Button>
            </ButtonRow>
          </form>
        </PanelBody>
      </AddPanel>
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
  const { pickupLabel, orderByLabel } = parsePickupDayText(pickupDay.deadlineText);
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
        <CardHeader>
          <CardHeaderText>
            <PickupDayTitle>{pickupLabel}</PickupDayTitle>
            {orderByLabel && <PickupDayMeta>order by {orderByLabel}</PickupDayMeta>}
          </CardHeaderText>
          <ActionRow>
            <Button type="button" size="xs" variant="secondary" onClick={handleEdit}>
              Edit
            </Button>
            <Button type="button" size="xs" variant="danger" data-icon="true" onClick={onRemove}>
              x
            </Button>
          </ActionRow>
        </CardHeader>
      ) : (
        <>
          <EditPanel>
            <InlineEditor>
              <FieldStack>
                <FieldLabel htmlFor={`pickup_day_${pickupDay.id}_pickup_at`}>
                  Pickup at:
                </FieldLabel>
                <DateInput
                  id={`pickup_day_${pickupDay.id}_pickup_at`}
                  type="datetime-local"
                  value={pickupAtValue}
                  onChange={(event) => setPickupAtValue(event.target.value)}
                />
              </FieldStack>
              <FieldStack>
                <FieldLabel htmlFor={`pickup_day_${pickupDay.id}_order_deadline_at`}>
                  Order deadline at:
                </FieldLabel>
                <DateInput
                  id={`pickup_day_${pickupDay.id}_order_deadline_at`}
                  type="datetime-local"
                  value={deadlineValue}
                  onChange={(event) => setDeadlineValue(event.target.value)}
                />
              </FieldStack>
            </InlineEditor>
          </EditPanel>
          <CardFooter>
            <Button type="button" size="sm" onClick={handleSave} disabled={!isDirty}>
              Save
            </Button>
            <Button type="button" size="sm" variant="secondary" onClick={handleCancel}>
              Cancel
            </Button>
          </CardFooter>
        </>
      )}
    </>
  );
}

const ButtonRow = styled.div`
  margin: 0.85rem 0 0;
`;

const ActionRow = styled.div`
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  margin-left: auto;
`;

const List = styled.div`
  margin: 0.75rem 0 0;
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
`;

const PickupDayCard = styled(Panel).attrs({ role: "listitem" })`
  flex: 0 0 350px;
  max-width: 350px;
  padding: 0;
  overflow: hidden;
  box-shadow: 0 8px 18px rgba(0, 0, 0, 0.08);
`;

const CardHeader = styled.div`
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  padding: 0.7rem 0.9rem;
  background: #f6f5ff;
  border-bottom: 1px solid #e6e6ee;
`;

const CardHeaderText = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
  flex: 1 1 auto;
`;

const PickupDayTitle = styled.h3`
  margin: 0;
  font-size: 1rem;
  font-weight: 600;
  color: #2e2927;
`;

const PickupDayMeta = styled.p`
  margin: 0;
  font-size: 0.9rem;
  color: #6b6b6b;
`;

const AddPanel = styled(Panel)`
  margin-top: 1.5rem;
`;

const LeadtimeActions = styled.div`
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-top: 0.5rem;
  small {
    color: #6b6b6b;
  }
`;

const InlineEditor = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 0.9rem 1.2rem;
`;

const DateInput = styled(ControlInput)`
  width: 100%;
  padding: 0.2rem 0.5rem;
  font-size: 0.85rem;
`;

const FieldStack = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.35rem;
`;

const FieldLabel = styled.label`
  color: #4a4a4a;
  font-weight: 600;
  font-size: 0.9rem;
`;

const EditPanel = styled.div`
  padding: 0.9rem;
  background: #f6f5ff;
  border-bottom: 1px solid #e6e6ee;
`;

const CardFooter = styled.div`
  display: flex;
  gap: 0.5rem;
  padding: 0.75rem 0.9rem 0.85rem;
  border-top: 1px solid #e6e6ee;
  background: #fff;
`;
