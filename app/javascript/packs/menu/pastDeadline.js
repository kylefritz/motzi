import moment from "moment";

export function pastDeadline(deadline) {
  const now = moment();
  return now > moment(deadline);
}
