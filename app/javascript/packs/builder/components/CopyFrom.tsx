import React from "react";
import styled from "styled-components";

import type { AdminMenuBuilderResponse } from "../../../types/api";
import { Button } from "./ui/Button";
import { Panel, PanelBody, PanelHeader } from "./ui/Panel";
import { ControlSelect } from "./ui/FormControls";

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
          <MenuSelect
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
          </MenuSelect>
        </FieldRow>
        <CheckboxRow>
          <CopyNotesContainer>
            <PanelHeader>Copy notes</PanelHeader>
            <PanelBody>
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
            </PanelBody>
          </CopyNotesContainer>
        </CheckboxRow>
        <Row>
          <Button type="submit">Copy</Button>
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

const CopyNotesContainer = styled(Panel)`
  display: inline-flex;
  flex-direction: column;
  gap: 0.4rem;
  padding: 0.65rem 0.8rem;
`;

const MenuSelect = styled(ControlSelect)`
  min-width: 320px;
`;

const CopyNotesOptions = styled.div`
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem 1.25rem;
`;

const CopyNotesHint = styled.span`
  color: #7a7a7a;
  font-size: 85%;
`;

const Hint = styled.span`
  margin-left: 0.75rem;
  color: #6b6b6b;
  font-size: 90%;
`;
