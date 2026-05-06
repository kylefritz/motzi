import React, { useState } from "react";
import axios from "axios";
import { reportException } from "../../lib/errorReporter";
import { getSettingsContext } from "./Contexts";
import type { MenuUser } from "../../types/api";

type EmailSettingsProps = {
  user: MenuUser;
  onBack: () => void;
};

type Preferences = Pick<
  MenuUser,
  "receiveWeeklyMenu" | "receiveHaventOrderedReminder" | "receiveDayOfReminder"
>;

const styles = {
  card: {
    background: "white",
    borderRadius: 12,
    padding: "28px 32px",
    maxWidth: 440,
    margin: "0 auto",
    boxShadow: "none",
  } as React.CSSProperties,
  heading: {
    fontFamily: "'Oswald', sans-serif",
    color: "#352C63",
    fontSize: 22,
    fontWeight: 400,
    textAlign: "center" as const,
    marginBottom: 4,
  } as React.CSSProperties,
  subtitle: {
    textAlign: "center" as const,
    color: "#999",
    fontSize: 14,
    marginBottom: 24,
  } as React.CSSProperties,
  row: {
    display: "flex",
    alignItems: "flex-start",
    padding: "14px 0",
    borderBottom: "1px solid #f0e8da",
  } as React.CSSProperties,
  rowLast: {
    display: "flex",
    alignItems: "flex-start",
    padding: "14px 0",
  } as React.CSSProperties,
  labelCol: {
    flex: 1,
  } as React.CSSProperties,
  label: {
    fontWeight: 500,
    fontSize: 15,
    color: "#2E2927",
    marginBottom: 2,
  } as React.CSSProperties,
  description: {
    fontSize: 13,
    color: "#999",
    lineHeight: 1.4,
  } as React.CSSProperties,
  disabledLabel: {
    fontWeight: 500,
    fontSize: 15,
    color: "#ccc",
    marginBottom: 2,
  } as React.CSSProperties,
  disabledDescription: {
    fontSize: 13,
    color: "#ccc",
    lineHeight: 1.4,
  } as React.CSSProperties,
  backLink: {
    color: "#352C63",
    fontSize: 14,
    textDecoration: "none",
  } as React.CSSProperties,
  saveBtn: {
    display: "block",
    width: "100%",
    marginTop: 24,
    padding: "10px 0",
    background: "#D5482C",
    color: "white",
    border: "none",
    borderRadius: 6,
    fontSize: 16,
    fontWeight: 500,
    cursor: "pointer",
    letterSpacing: "0.02em",
  } as React.CSSProperties,
  saveBtnDisabled: {
    display: "block",
    width: "100%",
    marginTop: 24,
    padding: "10px 0",
    background: "#e8a99b",
    color: "white",
    border: "none",
    borderRadius: 6,
    fontSize: 16,
    fontWeight: 500,
    cursor: "not-allowed",
    letterSpacing: "0.02em",
  } as React.CSSProperties,
  savedBtn: {
    display: "block",
    width: "100%",
    marginTop: 24,
    padding: "10px 0",
    background: "#352C63",
    color: "white",
    border: "none",
    borderRadius: 6,
    fontSize: 16,
    fontWeight: 500,
    letterSpacing: "0.02em",
  } as React.CSSProperties,
  toggle: {
    width: 44,
    height: 24,
    borderRadius: 12,
    border: "none",
    cursor: "pointer",
    position: "relative" as const,
    transition: "background 0.2s",
    flexShrink: 0,
    marginLeft: 12,
    marginTop: 2,
    padding: 0,
  } as React.CSSProperties,
  toggleKnob: {
    width: 18,
    height: 18,
    borderRadius: "50%",
    background: "white",
    position: "absolute" as const,
    top: 3,
    transition: "left 0.2s",
    boxShadow: "0 1px 3px rgba(0,0,0,0.15)",
  } as React.CSSProperties,
};

type ToggleRowProps = {
  label: string;
  description: string;
  checked: boolean;
  disabled?: boolean;
  onChange: () => void;
  last?: boolean;
  id: string;
};

function ToggleRow({
  label,
  description,
  checked,
  disabled,
  onChange,
  last,
  id,
}: ToggleRowProps) {
  return (
    <div style={last ? styles.rowLast : styles.row}>
      <div style={styles.labelCol}>
        <div style={disabled ? styles.disabledLabel : styles.label}>
          {label}
        </div>
        <div
          style={disabled ? styles.disabledDescription : styles.description}
        >
          {description}
        </div>
      </div>
      <button
        type="button"
        role="switch"
        id={id}
        aria-checked={checked}
        aria-label={label}
        disabled={disabled}
        onClick={onChange}
        style={{
          ...styles.toggle,
          background: disabled ? "#e0ddd8" : checked ? "#352C63" : "#ccc",
          cursor: disabled ? "not-allowed" : "pointer",
        }}
      >
        <div
          style={{
            ...styles.toggleKnob,
            left: checked ? 23 : 3,
          }}
        />
      </button>
    </div>
  );
}

export default function EmailSettings({ user, onBack }: EmailSettingsProps) {
  const { onRefresh } = getSettingsContext();
  const [prefs, setPrefs] = useState<Preferences>({
    receiveWeeklyMenu: user.receiveWeeklyMenu,
    receiveHaventOrderedReminder: user.receiveHaventOrderedReminder,
    receiveDayOfReminder: user.receiveDayOfReminder,
  });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  const toggle = (key: keyof Preferences) => {
    setSaved(false);
    setPrefs((prev) => {
      const next = { ...prev, [key]: !prev[key] };
      // Auto-clear dependent preference when weekly menu is turned off
      if (key === "receiveWeeklyMenu" && !next.receiveWeeklyMenu) {
        next.receiveHaventOrderedReminder = false;
      }
      return next;
    });
  };

  const handleSave = () => {
    setSaving(true);
    axios
      .patch("/email_preferences", {
        uid: user.hashid,
        receive_weekly_menu: prefs.receiveWeeklyMenu,
        receive_havent_ordered_reminder: prefs.receiveHaventOrderedReminder,
        receive_day_of_reminder: prefs.receiveDayOfReminder,
      })
      .then(() => {
        setSaved(true);
        onRefresh?.();
      })
      .catch((err) => {
        console.error("Failed to save email preferences", err);
        reportException(err, { kind: "email_settings_save" });
        window.alert("Couldn't save preferences. Please try again.");
      })
      .finally(() => setSaving(false));
  };

  const btnStyle = saving
    ? styles.saveBtnDisabled
    : saved
      ? styles.savedBtn
      : styles.saveBtn;

  return (
    <div style={{ paddingTop: 8, paddingBottom: 24 }}>
      <div className="mb-3 text-center">
        <a
          href="#"
          onClick={(e) => {
            e.preventDefault();
            onBack();
          }}
          style={styles.backLink}
        >
          &larr; Back to menu
        </a>
      </div>

      <div style={styles.card}>
        <h5 style={styles.heading}>Email Settings</h5>
        <p style={styles.subtitle}>{user.name}</p>

        <ToggleRow
          id="receiveWeeklyMenu"
          label="Weekly menu"
          description="The weekly menu email"
          checked={prefs.receiveWeeklyMenu}
          onChange={() => toggle("receiveWeeklyMenu")}
        />

        <ToggleRow
          id="receiveHaventOrderedReminder"
          label="Order reminder"
          description="Reminder if you haven't ordered yet"
          checked={prefs.receiveHaventOrderedReminder}
          disabled={!prefs.receiveWeeklyMenu}
          onChange={() => toggle("receiveHaventOrderedReminder")}
        />

        <ToggleRow
          id="receiveDayOfReminder"
          label="Pickup reminder"
          description="Day-of reminder to pick up your order"
          checked={prefs.receiveDayOfReminder}
          onChange={() => toggle("receiveDayOfReminder")}
          last
        />

        <button
          type="button"
          onClick={handleSave}
          disabled={saving}
          style={btnStyle}
        >
          {saving ? "Saving..." : saved ? "Saved!" : "Save Preferences"}
        </button>
      </div>
    </div>
  );
}
