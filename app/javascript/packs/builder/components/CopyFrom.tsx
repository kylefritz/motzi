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
          <label>
            <input
              type="checkbox"
              name="copy_subscriber_note"
              value="1"
              defaultChecked
            />
            Subscriber note
          </label>
          <label>
            <input
              type="checkbox"
              name="copy_menu_note"
              value="1"
              defaultChecked
            />
            Menu note
          </label>
          <label>
            <input
              type="checkbox"
              name="copy_day_of_note"
              value="1"
              defaultChecked
            />
            Day of note
          </label>
        </CheckboxRow>
        <Row>
          <PrimaryBtn type="submit">Copy from</PrimaryBtn>
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
  }
  select {
    min-width: 320px;
  }
`;

const CheckboxRow = styled(Row)`
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.25rem;
  label {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    margin-right: 0;
  }
`;

const PrimaryBtn = styled.button`
  padding: 0.4rem 1rem;
  font-size: 95%;
  border: 1px solid #3f3a80;
  background: #3f3a80;
  color: #fff;
  border-radius: 6px;
`;

const Hint = styled.span`
  margin-left: 0.75rem;
  color: #6b6b6b;
  font-size: 90%;
`;
