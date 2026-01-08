export function convertTemperature(value, from, to, precision = 2) {
  let result;
  if (from === "C" && to === "F") {
    result = value * (9 / 5) + 32;
  } else if (from === "F" && to === "C") {
    result = (value - 32) * (5 / 9);
  } else if (from === "K" && to === "C") {
    result = value - 273.15;
  } else if (from === "C" && to === "K") {
    result = value + 273.15;
  } else if (from === "K" && to === "F") {
    result = value * (9 / 5) - 459.67;
  } else if (from === "F" && to === "K") {
    result = (value + 459.67) * (5 / 9);
  } else {
    throw new Error(`Unsupported temperature conversion: ${from} to ${to}`);
  }
  return Number(result.toFixed(precision));
}
