import React from "react";
import styled from "styled-components";
import { AppBar, Tabs, Tab, Box } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";

import MenuItem from "./Item";
import Adder from "./Adder";
import { PickupDays } from "./PickupDay";
import type {
  AdminItem,
  AdminMenuBuilderResponse,
  AdminMenuItem,
  AdminPickupDay,
} from "../../types/api";

type LayoutProps = {
  allItems: AdminItem[];
  menu: AdminMenuBuilderResponse;
};

export default function SimpleTabs({ allItems, menu }: LayoutProps) {
  const classes = useStyles();
  const [tab, setTab] = React.useState(0);
  const handleChange = (_event: React.ChangeEvent<{}>, newTab: number) => {
    setTab(newTab);
  };
  const { pickupDays, leadtimeHours, recentMenus } = menu;
  return (
    <div className={classes.root}>
      <CopyFrom menuId={menu.id} recentMenus={recentMenus} />
      <hr />
      <PickupDays pickupDays={pickupDays} leadtimeHours={leadtimeHours} />
      <hr />
      <h2>Menu Items</h2>
      <AppBar position="static">
        <Tabs
          value={tab}
          onChange={handleChange}
          aria-label="simple tabs example"
        >
          <Tab label="All" {...a11yProps(0)} />
          <Tab label="Subscribers" {...a11yProps(1)} />
          <Tab label="Marketplace" {...a11yProps(2)} />
        </Tabs>
      </AppBar>
      <TabPanel value={tab} index={0}>
        <ItemGrid {...{ menuItems: menu.items, pickupDays }} />
      </TabPanel>
      <TabPanel value={tab} index={1}>
        <ItemGrid
          {...{
            menuItems: menu.items.filter((i) => i.subscriber),
            pickupDays,
          }}
        />
      </TabPanel>
      <TabPanel value={tab} index={2}>
        <ItemGrid
          {...{
            menuItems: menu.items.filter((i) => i.marketplace),
            pickupDays,
          }}
        />
      </TabPanel>

      <Adder
        items={allItems}
        not={menu.items.map(({ name }) => name)}
        pickupDays={menu.pickupDays}
      />
    </div>
  );
}

type TabPanelProps = React.HTMLAttributes<HTMLDivElement> & {
  children: React.ReactNode;
  value: number;
  index: number;
};

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`simple-tabpanel-${index}`}
      aria-labelledby={`simple-tab-${index}`}
      {...other}
    >
      {value === index && <Box p={3}>{children}</Box>}
    </div>
  );
}

type RecentMenu = AdminMenuBuilderResponse["recentMenus"][number];

function CopyFrom({
  menuId,
  recentMenus,
}: {
  menuId: number;
  recentMenus: RecentMenu[];
}) {
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

type ItemGridProps = {
  menuItems: AdminMenuItem[];
  pickupDays: AdminPickupDay[];
};

function ItemGrid({ menuItems, pickupDays }: ItemGridProps) {
  if (menuItems.length === 0) {
    return (
      <p>
        <em>no items</em>
      </p>
    );
  }
  return (
    <Grid>
      {menuItems.map((i) => (
        <MenuItem key={i.menuItemId} {...i} menuPickupDays={pickupDays} />
      ))}
    </Grid>
  );
}

function a11yProps(index: number) {
  return {
    id: `simple-tab-${index}`,
    "aria-controls": `simple-tabpanel-${index}`,
  };
}

const useStyles = makeStyles((theme) => ({
  root: {
    flexGrow: 1,
    backgroundColor: theme.palette.background.paper,
  },
}));

const Grid = styled.div`
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
`;
