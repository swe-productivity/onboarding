import * as temperature from "./lib/temperature.js";
import * as distance from "./lib/distance.js";
import * as weight from "./lib/weight.js";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const defaults = JSON.parse(
  readFileSync(join(__dirname, "../config/defaults.json"), "utf-8")
);

function roundToPrecision(value, precision) {
  return Math.round(value * Math.pow(10, precision)) / Math.pow(10, precision);
}

function detectTypeFromUnit(unit) {
  const distanceUnits = ["km", "mi"];
  const weightUnits = ["g", "oz"];
  const temperatureUnits = ["C", "F"];
  
  if (distanceUnits.includes(unit)) return "distance";
  if (weightUnits.includes(unit)) return "weight";
  if (temperatureUnits.includes(unit)) return "temperature";
  throw new Error(`Unknown unit: ${unit}`);
}

function getCommonUnit(type) {
  switch (type) {
    case "distance":
      return "km";
    case "weight":
      return "g";
    case "temperature":
      return "C";
    default:
      throw new Error(`Unknown type: ${type}`);
  }
}

export function compare(value1, unit1, value2, unit2) {
  const type1 = detectTypeFromUnit(unit1);
  const type2 = detectTypeFromUnit(unit2);
  
  if (type1 !== type2) {
    throw new Error(`Cannot compare ${unit1} (${type1}) with ${unit2} (${type2})`);
  }
  
  const type = type1;
  const commonUnit = getCommonUnit(type);
  
  // Convert both values to common unit
  let converted1 = value1;
  let converted2 = value2;
  
  if (unit1 !== commonUnit) {
    converted1 = convert(type, value1, unit1, commonUnit);
  }
  if (unit2 !== commonUnit) {
    converted2 = convert(type, value2, unit2, commonUnit);
  }
  
  const rounded1 = roundToPrecision(converted1, defaults.precision);
  const rounded2 = roundToPrecision(converted2, defaults.precision);
  const difference = Math.abs(rounded1 - rounded2);
  const isEqual = difference === 0;
  
  const larger = rounded1 > rounded2 ? { value: value1, unit: unit1, converted: rounded1 } 
                                      : rounded2 > rounded1 ? { value: value2, unit: unit2, converted: rounded2 }
                                      : null;
  const smaller = rounded1 < rounded2 ? { value: value1, unit: unit1, converted: rounded1 }
                                      : rounded2 < rounded1 ? { value: value2, unit: unit2, converted: rounded2 }
                                      : null;
  
  return {
    type,
    value1: { value: value1, unit: unit1, converted: rounded1 },
    value2: { value: value2, unit: unit2, converted: rounded2 },
    commonUnit,
    difference: roundToPrecision(difference, defaults.precision),
    isEqual,
    larger,
    smaller
  };
}

export function convert(type, value, from, to) {
  let result;
  switch (type) {
    case "temperature":
      result = temperature.convertTemperature(
        value,
        from || defaults.temperature.defaultFrom,
        to || defaults.temperature.defaultTo
      );
      break;
    case "distance":
      result = distance.convertDistance(value, from, to);
      break;
    case "weight":
      result = weight.convertWeight(value, from, to);
      break;
    default:
      throw new Error("Unknown type " + type);
  }
  return roundToPrecision(result, defaults.precision);
}
