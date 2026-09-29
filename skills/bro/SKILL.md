---
name: bro
description: Restate the last message in plain human language, with no jargon.
disable-model-invocation: true
metadata:
  upstream:
    repo: dmmulroy/skills
    path: bro
    commit: cbd1929589267453029859a43d2ecf411c865b54
    status: modified
    notes:
      - local: keep the original language of the last message.
      - local: borrow wait-what's re-pitch-with-context cue from mattpocock/skills wait-what.
---

Restate your last message. Stop using jargon and speak coherently. State it more simply and concisely, like one human talking to another. Keep the original language of that message.

If the last message did not land, re-pitch it with a little context first.
