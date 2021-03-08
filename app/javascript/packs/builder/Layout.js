import React from "react";
import styled from "styled-components";
import { AppBar, Tabs, Tab, Box } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";

import MenuItem from "./Item";
import Adder from "./Adder";

export default function SimpleTabs({
  allItems,
  menu,
  handleAddItem,
  handleRemoveItem,
}) {
  const classes = useStyles();
  const [value, setValue] = React.useState(0);
  const isSubscriber = value === 0;
  const handleChange = (event, newValue) => {
    setValue(newValue);
  };

  const subscriber = menu.items.filter((i) => i.subscriber);
  const marketplace = menu.items.filter((i) => i.marketplace);

  return (
    <div className={classes.root}>
      <AppBar position="static">
        <Tabs
          value={value}
          onChange={handleChange}
          aria-label="simple tabs example"
        >
          <Tab label="Subscribers" {...a11yProps(0)} />
          <Tab label="Marketplace" {...a11yProps(1)} />
        </Tabs>
      </AppBar>
      <TabPanel value={value} index={0}>
        <ItemGrid menuItems={subscriber} {...{ handleRemoveItem }} />
      </TabPanel>
      <TabPanel value={value} index={1}>
        <ItemGrid menuItems={marketplace} {...{ handleRemoveItem }} />
      </TabPanel>

      <Adder
        items={allItems}
        not={(isSubscriber ? subscriber : marketplace).map(({ name }) => name)}
        pickupDays={menu.pickupDays}
        onAdd={(item) => handleAddItem(item)}
      />
    </div>
  );
}

function TabPanel(props) {
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

function ItemGrid({ menuItems }) {
  if (items.length == 0) {
    return (
      <p>
        <em>no items</em>
      </p>
    );
  }
  return (
    <Grid>
      {menuItems.map((i) => (
        <MenuItem key={i.id} {...i} onRemove={() => handleRemoveItem(i.id)} />
      ))}
    </Grid>
  );
}

function a11yProps(index) {
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
