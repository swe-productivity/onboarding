import { test } from "node:test";
import { strictEqual } from "node:assert";
import { convertTemperature } from "../src/lib/temperature.js";
import { convertDistance } from "../src/lib/distance.js";
import { convertWeight } from "../src/lib/weight.js";

// Temperature - Kelvin tests
test("converts Kelvin to Celsius (freezing point)", () => {
  strictEqual(convertTemperature(273.15, "K", "C"), 0);
});

test("converts Kelvin to Celsius (boiling point)", () => {
  strictEqual(convertTemperature(373.15, "K", "C"), 100);
});

test("converts Celsius to Kelvin (freezing point)", () => {
  strictEqual(convertTemperature(0, "C", "K"), 273.15);
});

test("converts Celsius to Kelvin (boiling point)", () => {
  strictEqual(convertTemperature(100, "C", "K"), 373.15);
});

test("converts Kelvin to Fahrenheit (freezing point)", () => {
  strictEqual(convertTemperature(273.15, "K", "F"), 32);
});

test("converts Kelvin to Fahrenheit (absolute zero)", () => {
  strictEqual(convertTemperature(0, "K", "F"), -459.67);
});

test("converts Fahrenheit to Kelvin (freezing point)", () => {
  strictEqual(convertTemperature(32, "F", "K"), 273.15);
});

test("converts Fahrenheit to Kelvin (absolute zero)", () => {
  strictEqual(convertTemperature(-459.67, "F", "K"), 0);
});

// Distance - Meters tests
test("converts meters to kilometers", () => {
  strictEqual(convertDistance(1000, "m", "km"), 1);
});

test("converts meters to kilometers (5000m)", () => {
  strictEqual(convertDistance(5000, "m", "km"), 5);
});

test("converts kilometers to meters", () => {
  strictEqual(convertDistance(1, "km", "m"), 1000);
});

test("converts kilometers to meters (2.5km)", () => {
  strictEqual(convertDistance(2.5, "km", "m"), 2500);
});

test("converts meters to miles", () => {
  strictEqual(convertDistance(1609.344, "m", "mi"), 1);
});

test("converts meters to miles (1000m)", () => {
  strictEqual(convertDistance(1000, "m", "mi"), 0.62);
});

test("converts miles to meters", () => {
  strictEqual(convertDistance(1, "mi", "m"), 1609.34);
});

test("converts miles to meters (5mi)", () => {
  strictEqual(convertDistance(5, "mi", "m"), 8046.72);
});

// Weight - Pounds tests
test("converts pounds to grams", () => {
  strictEqual(convertWeight(1, "lb", "g"), 453.59);
});

test("converts pounds to grams (2lb)", () => {
  strictEqual(convertWeight(2, "lb", "g"), 907.18);
});

test("converts grams to pounds", () => {
  strictEqual(convertWeight(453.592, "g", "lb"), 1);
});

test("converts grams to pounds (1000g)", () => {
  strictEqual(convertWeight(1000, "g", "lb"), 2.2);
});

test("converts pounds to ounces", () => {
  strictEqual(convertWeight(1, "lb", "oz"), 16);
});

test("converts pounds to ounces (2.5lb)", () => {
  strictEqual(convertWeight(2.5, "lb", "oz"), 40);
});

test("converts ounces to pounds", () => {
  strictEqual(convertWeight(16, "oz", "lb"), 1);
});

test("converts ounces to pounds (8oz)", () => {
  strictEqual(convertWeight(8, "oz", "lb"), 0.5);
});

// Edge cases
test("handles very small meter distances", () => {
  strictEqual(convertDistance(1, "m", "mi"), 0); // 0.000621371 rounds to 0.00
});

test("handles absolute zero in Kelvin to Celsius", () => {
  strictEqual(convertTemperature(0, "K", "C"), -273.15);
});

test("handles room temperature in Celsius to Kelvin", () => {
  strictEqual(convertTemperature(20, "C", "K"), 293.15);
});

test("handles typical weight conversion (100g to lb)", () => {
  strictEqual(convertWeight(100, "g", "lb"), 0.22);
});
