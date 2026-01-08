# Tiny Unit Converter

Practice the core workflows from both onboarding guides inside this mini Node.js project. All exercises revolve around a unit conversion toolkit so you can practice building, testing, and documenting code using Cursor and Claude.

## Project Overview

This project is a conversion toolkit that consists of three number conversion modules (temperature, distance, weight) through a shared dispatcher and CLI.

## Project Structure

```
tiny-unit-converter/
├── package.json
├── README.md
├── config/
│   └── defaults.json
├── bin/
│   └── cli.js
├── src/
│   ├── index.js
│   ├── convert.js
│   └── lib/
│       ├── temperature.js
│       ├── distance.js
│       └── weight.js
└── tests/
    ├── precision.test.js
    ├── validation.test.js
    └── temperature.test.js
```

## Setup

```bash
npm install
```

## Usage

```bash
# Temperature conversions
npx convert temperature 100 C F
npx convert temperature 273.15 K C
npx convert temperature 0 K F

# Distance conversions
npx convert distance 5 km mi
npx convert distance 1000 m km
npx convert distance 1609 m mi

# Weight conversions
npx convert weight 200 g oz
npx convert weight 1 lb g
npx convert weight 16 oz lb
```

## Run tests

```bash
npm test
```

> **Tip:** you will see failing tests when you run `npm test` -- this is part of the exercise.

## Claude Code Feature Tour

### 1. Codebase Exploration

1. Launch Claude Code from the playground directory:

   ```bash
   cd playground
   claude
   ```

2. Ask Claude Code to analyze the project structure and identify potential improvements:
   ```
   What does this codebase do? Point me to the CLI entry, the main dispatcher, and any failing tests.
   ```

> **Tip:** Run /resume to jump back into an old conversation anytime.

### 2. Quick Changes

The current `convert()` function accepts any input without validation: it will try to process invalid numbers like "abc" or unsupported units like "xyz".

Ask Claude to add input validation that rejects non-numeric values and unknown unit codes, then write tests for these validation cases.

> **Tip:** Hit Esc to quickly cancel a generation mid-stream.

### 3. New Features

For larger features, turn on **Plan Mode** before prompting:

1. Press `Shift+Tab` to enter plan mode, then ask Claude to extend the converter with new units:

- Kelvin for temperature
- meters for distance
- pounds for weight

  For example, users should be able to run "convert temperature 273 K C" or "convert distance 1000 m km".

2. Claude will generate a step-by-step plan. Review and adjust the steps as needed using `Ctrl-g`.

3. Claude will work through each step, marking items complete as it goes.

> **Tip:** Tap Tab to toggle Thinking mode on for reasoning.

## Cursor Feature Tour

### 1. Ask Questions

1. Open the **Ask** sidebar, and ask Cursor about the behavior around precision defaults.

   ```
   Can you walk me through how the converters decide what precision to use when formatting distance and weight values?
   ```

> **Tip:** Add context by dragging files/folders into the sidebar or referencing them with @ in chat.

### 2. Plan Features

1. Open the **Plan** sidebar and ask Cursor to help you add precision formatting to all converters (distance, weight, temperature).
2. Review the suggested tasks and edit them so they match how you want to implement the feature.
3. Approve the plan with the finalized tasks.

> **Tip:** Switch models by opening the chat and choosing a model instead of “Auto.”

### 3. Feature Implementation

1. Once the plan is approved, open **Agent** chat and ask it to add a "compare" CLI command that contrasts two values (for example: `convert compare 5 km 3 mi`).
2. Review the generated diff carefully before accepting changes.
3. If behavior isn’t quite right, iterate with follow-up prompts until everything passes.

> **Tip:** Use Cmd/Ctrl + K for fast in-line code edits.
