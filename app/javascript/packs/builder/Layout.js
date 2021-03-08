import React from "react";
import styled from "styled-components";
import { AppBar, Tabs, Tab, Box, Typography } from "@material-ui/core";
import { makeStyles } from "@material-ui/core/styles";

import MenuItem from "./Item";
import Adder from "./Adder";

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
      {value === index && (
        <Box p={3}>
          <Typography>{children}</Typography>
        </Box>
      )}
    </div>
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

export default function SimpleTabs({
  allItems,
  menuItems,
  handleAddItem,
  handleRemoveItem,
}) {
  const classes = useStyles();
  const [value, setValue] = React.useState(0);
  const isSubscriber = value === 0;
  const handleChange = (event, newValue) => {
    setValue(newValue);
  };

  const subscriber = menuItems.filter((i) => i.subscriber);
  const marketplace = menuItems.filter((i) => i.marketplace);

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
        onAdd={(item) => handleAddItem(item)}
      />
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

const App = styled.div`
  all: unset;
`;

const Grid = styled.div`
  // display: grid;
  // grid-template-columns: auto auto auto auto auto;
  // column-gap: 10px;
  // row-gap: 15px;
  // columns: auto;
  // columns: 275px auto;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
`;
