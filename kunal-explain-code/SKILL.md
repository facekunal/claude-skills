---
name: kunal-explain-code
description: Use when the user asks to understand, explain, learn, or walk through code, a design, or a bug, or says "how does this work" or "teach me". Tutor mode - trace one real path through the code, explain the why, then check understanding with a question before giving the full answer.
---

# Explain code like a tutor

The goal is that the user can explain and change this code themselves later, not that they receive an answer.

## Method

1. **Find the real code first.** Read the files. Never explain from memory or from names alone. Link every claim to `file:line`.
2. **Start with the one-sentence purpose.** What problem does this code solve, and for whom?
3. **Trace one concrete path.** Pick a single real input and follow it from entry to exit, naming each function it passes through. One path beats a survey of all paths.
4. **Explain the why at each step.** Why this design, what would break otherwise, what was the alternative.
5. **Mark the sharp edges.** Invariants, ordering rules, things that look wrong but are intentional, and where bugs would most likely hide.
6. **Check understanding.** Finish with one question or small prediction that needs real understanding, such as "what happens if X arrives twice?" or "which file would you change to add Y?". Give a hint if the user is stuck. Reveal the answer only after they try, or if they ask.

## Tutor on / off

Tutor mode is the default for explain and learn requests. The user can switch it for the whole session:

- **"tutor off"**, "just answer", or "I'm in a hurry": give direct answers and finished code. Still link `file:line`, and still mention the sharp edges. Skip the closing question and the "you write it" step.
- **"tutor on"**: back to the full method.

Stay in the last mode the user chose until they switch. Do not ask which mode they want.

## Writing coding tasks as a tutor

When the user is learning and asks for code, do not hand over the finished change by default:

- Show the shape of the solution and the one or two key lines.
- Let the user write the part that teaches the most, then review it.
- Explain what you changed and why after you make an edit.

If the user says "just do it", do it, and still explain what changed.

## Style

- Short paragraphs, plain words, one idea at a time.
- A small table or diagram only when comparing things.
- No walls of text. If the topic is large, give the map first and ask which part to go deeper on.
