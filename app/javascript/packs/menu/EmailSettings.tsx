import React, { useState } from "react";
import axios from "axios";
import type { MenuUser } from "../../types/api";

type EmailSettingsProps = {
  user: MenuUser;
  onBack: () => void;
};

type Preferences = {
  receiveWeeklyMenu: boolean;
  receiveHaventOrderedReminder: boolean;
  receiveDayOfReminder: boolean;
};

export default function EmailSettings({ user, onBack }: EmailSettingsProps) {
  const [prefs, setPrefs] = useState<Preferences>({
    receiveWeeklyMenu: user.receiveWeeklyMenu,
    receiveHaventOrderedReminder: user.receiveHaventOrderedReminder,
    receiveDayOfReminder: user.receiveDayOfReminder,
  });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  const toggle = (key: keyof Preferences) => {
    setSaved(false);
    setPrefs((prev) => ({ ...prev, [key]: !prev[key] }));
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
      })
      .catch((err) => {
        console.error("Failed to save email preferences", err);
        window.alert("Couldn't save preferences. Please try again.");
      })
      .finally(() => setSaving(false));
  };

  return (
    <>
      <div className="mb-3">
        <a
          href="#"
          onClick={(e) => {
            e.preventDefault();
            onBack();
          }}
          className="text-decoration-none"
        >
          &larr; Back to menu
        </a>
      </div>

      <h5>Email Settings</h5>

      <div className="form-check mb-2">
        <input
          type="checkbox"
          className="form-check-input"
          id="receiveWeeklyMenu"
          checked={prefs.receiveWeeklyMenu}
          onChange={() => toggle("receiveWeeklyMenu")}
        />
        <label className="form-check-label" htmlFor="receiveWeeklyMenu">
          Weekly menu email
        </label>
      </div>

      <div className="form-check mb-2">
        <input
          type="checkbox"
          className="form-check-input"
          id="receiveHaventOrderedReminder"
          checked={prefs.receiveHaventOrderedReminder}
          disabled={!prefs.receiveWeeklyMenu}
          onChange={() => toggle("receiveHaventOrderedReminder")}
        />
        <label
          className="form-check-label"
          htmlFor="receiveHaventOrderedReminder"
        >
          &ldquo;Haven&rsquo;t ordered&rdquo; reminder
        </label>
        {!prefs.receiveWeeklyMenu && (
          <small className="d-block text-muted">
            Only available when weekly menu email is on
          </small>
        )}
      </div>

      <div className="form-check mb-3">
        <input
          type="checkbox"
          className="form-check-input"
          id="receiveDayOfReminder"
          checked={prefs.receiveDayOfReminder}
          onChange={() => toggle("receiveDayOfReminder")}
        />
        <label className="form-check-label" htmlFor="receiveDayOfReminder">
          Day-of pickup reminder
        </label>
      </div>

      <button
        className="btn btn-primary"
        onClick={handleSave}
        disabled={saving}
      >
        {saving ? "Saving..." : saved ? "Saved!" : "Save"}
      </button>
    </>
  );
}
