export function convertWeight(value, from, to, precision = 2) {
  let result;
  if (from === "g" && to === "oz") {
    result = value / 28.3495;
  } else if (from === "oz" && to === "g") {
    result = value * 28.3495;
  } else if (from === "lb" && to === "g") {
    result = value * 453.592;
  } else if (from === "g" && to === "lb") {
    result = value / 453.592;
  } else if (from === "lb" && to === "oz") {
    result = value * 16;
  } else if (from === "oz" && to === "lb") {
    result = value / 16;
  } else {
    throw new Error(`Unsupported weight conversion: ${from} to ${to}`);
  }
  return Number(result.toFixed(precision));
}
