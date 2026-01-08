export function convertDistance(value, from, to, precision = 2) {
  let result;
  if (from === "km" && to === "mi") {
    result = value * 0.621371;
  } else if (from === "mi" && to === "km") {
    result = value / 0.621371;
  } else if (from === "m" && to === "km") {
    result = value / 1000;
  } else if (from === "km" && to === "m") {
    result = value * 1000;
  } else if (from === "m" && to === "mi") {
    result = value * 0.000621371;
  } else if (from === "mi" && to === "m") {
    result = value * 1609.344;
  } else {
    throw new Error(`Unsupported distance conversion: ${from} to ${to}`);
  }
  return Number(result.toFixed(precision));
}
