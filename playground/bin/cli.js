#!/usr/bin/env node
import { convert, compare } from "../src/convert.js";

const [,, command, ...args] = process.argv;

if (!command) {
  console.error("Usage: convert <type> <value> [from] [to]");
  console.error("   or: convert compare <value1> <unit1> <value2> <unit2>");
  process.exit(1);
}

if (command === "compare") {
  if (args.length < 4) {
    console.error("Usage: convert compare <value1> <unit1> <value2> <unit2>");
    console.error("Example: convert compare 5 km 3 mi");
    process.exit(1);
  }
  
  const [value1, unit1, value2, unit2] = args;
  try {
    const result = compare(Number(value1), unit1, Number(value2), unit2);
    
    console.log(`Comparison (${result.type}):`);
    console.log(`  ${result.value1.value} ${result.value1.unit} = ${result.value1.converted} ${result.commonUnit}`);
    console.log(`  ${result.value2.value} ${result.value2.unit} = ${result.value2.converted} ${result.commonUnit}`);
    console.log(`  Difference: ${result.difference} ${result.commonUnit}`);
    if (result.isEqual) {
      console.log(`  Values are equal`);
    } else {
      console.log(`  ${result.larger.value} ${result.larger.unit} is larger`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
} else {
  const [value, from, to] = args;
  
  if (!value) {
    console.error("Usage: convert <type> <value> [from] [to]");
    process.exit(1);
  }
  
  try {
    const result = convert(command, Number(value), from, to);
    console.log(result);
  } catch (error) {
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
}
