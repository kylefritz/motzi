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
    <>
      <h2>Copy from menu</h2>
      <p>Most recent 100 menus</p>
      <form method="POST" action={`/admin/menus/${menuId}/copy_from`}>
        <Row>
          <label htmlFor="original_menu_id">Menu:</label>
          <select
            id="original_menu_id"
            name="original_menu_id"
            defaultValue=""
            required
            disabled={recentMenus.length === 0}
          >
            <option value="" disabled>
              Select a menu
            </option>
            {recentMenus.map((menu) => (
              <option key={menu.id} value={menu.id}>
                {menu.name} ({menu.weekId})
              </option>
            ))}
          </select>
        </Row>
        <Row>
          <input type="submit" value="Copy from" />
        </Row>
      </form>
    </>
  );
}

const Row = styled.div`
  margin: 1rem 0;
  label {
    margin-right: 1rem;
  }
`;
