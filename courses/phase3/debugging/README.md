# Debugging Exercises

Four broken configurations for you to diagnose and fix. Each one contains a real bug that you might encounter while building hooks and tmux scripts.

## How to Use

1. Read the broken file
2. Identify the bug (the filename hints at the category, not the specific issue)
3. Write down what's wrong and why
4. Fix it
5. Test that your fix works

Don't run the broken files in production — some will cause real problems (like infinite loops).

## Exercise 1: broken-hook-01.sh

A Stop hook that's supposed to remind about MEMORY.md updates. Something causes it to run forever.

```bash
cat debugging/broken-hook-01.sh
```

## Exercise 2: broken-hook-02.sh

A PreToolUse hook that's supposed to block edits to log files. The blocking doesn't work — edits go through anyway.

```bash
cat debugging/broken-hook-02.sh
```

## Exercise 3: broken-hook-03.sh

A PreToolUse hook that's supposed to read the file path from JSON input. It never matches any files.

```bash
cat debugging/broken-hook-03.sh
```

## Exercise 4: broken-layout.sh

A tmux startup script that should create a 3-window layout. The commands end up in the wrong panes.

```bash
cat debugging/broken-layout.sh
```
