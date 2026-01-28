import React from "react";
import styled from "styled-components";

import type { AdminMenuBuilderResponse } from "../../../types/api";

type RecentMenu = AdminMenuBuilderResponse["recentMenus"][number];

type CopyFromProps = {
  menuId: number;
  recentMenus: RecentMenu[];
};

export default function CopyFrom({ menuId, recentMenus }: CopyFromProps) {
  return (
    <Section>
      <h2>Copy from menu</h2>
      <form method="POST" action={`/admin/menus/${menuId}/copy_from`}>
        <FieldRow>
          <label htmlFor="original_menu_id">Menu:</label>
          <select
            id="original_menu_id"
            name="original_menu_id"
            defaultValue=""
            required
            disabled={recentMenus.length === 0}
          >
            <option value="" disabled>
              Select from 100 most recent menus
            </option>
            {recentMenus.map((menu) => {
              const pickupDaysLabel = menu.pickupDaysLabel || "No pickup days";
              return (
                <option key={menu.id} value={menu.id}>
                  {menu.weekId} - {menu.name} - {pickupDaysLabel}
                </option>
              );
            })}
          </select>
        </FieldRow>
        <CheckboxRow>
          <CopyNotesContainer>
            <CopyNotesHeader>Copy notes</CopyNotesHeader>
            <CopyNotesOptions>
              <label>
                <input
                  type="checkbox"
                  name="copy_subscriber_note"
                  value="1"
                  defaultChecked
                />
                Subscriber
              </label>
              <label>
                <input
                  type="checkbox"
                  name="copy_menu_note"
                  value="1"
                  defaultChecked
                />
                Menu
              </label>
              <label>
                <input
                  type="checkbox"
                  name="copy_day_of_note"
                  value="1"
                  defaultChecked
                />
                Day of
              </label>
            </CopyNotesOptions>
            <CopyNotesHint>
              Copying won’t override an existing note.
            </CopyNotesHint>
          </CopyNotesContainer>
        </CheckboxRow>
        <Row>
          <PrimaryBtn type="submit">Copy</PrimaryBtn>
          <Hint>
            Copies pickup days and shifts them into this menu’s week.
          </Hint>
        </Row>
      </form>
    </Section>
  );
}

const Section = styled.section`
  margin-bottom: 1.25rem;
`;

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
  label {
    min-width: 70px;
    color: #4a4a4a;
    font-weight: 600;
  }
  select {
    min-width: 320px;
    padding: 0.45rem 0.6rem;
    border: 1px solid #d9d9d9;
    border-radius: 8px;
    background: #fff;
    box-shadow: 0 1px 0 rgba(0, 0, 0, 0.02);
  }
`;

const CheckboxRow = styled(Row)`
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 0.75rem 1.25rem;
  label {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    margin-right: 0;
  }
`;

const CopyNotesContainer = styled.div`
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 0.7rem 0.85rem;
  border: 1px solid #e3e3e3;
  border-radius: 10px;
  background: #fafafa;
`;

const CopyNotesHeader = styled.div`
  font-weight: 600;
  color: #444;
  font-size: 95%;
`;

const CopyNotesOptions = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.25rem;
  label {
    padding: 0.25rem 0.5rem;
    border: 1px solid #e6e6e6;
    border-radius: 8px;
    background: #fff;
  }
`;

const CopyNotesHint = styled.span`
  color: #7a7a7a;
  font-size: 85%;
`;

const PrimaryBtn = styled.button`
  padding: 0.5rem 1.2rem;
  font-size: 95%;
  border: 1px solid #3f3a80;
  background: #3f3a80;
  color: #fff;
  border-radius: 10px;
  box-shadow: 0 6px 16px rgba(63, 58, 128, 0.18);
  transition: transform 120ms ease, box-shadow 120ms ease,
    background-color 120ms ease;
  &:hover {
    background: #353070;
    box-shadow: 0 8px 18px rgba(63, 58, 128, 0.22);
    transform: translateY(-1px);
  }
  &:active {
    transform: translateY(0);
    box-shadow: 0 4px 10px rgba(63, 58, 128, 0.2);
  }
`;

const Hint = styled.span`
  margin-left: 0.75rem;
  color: #6b6b6b;
  font-size: 90%;
`;
