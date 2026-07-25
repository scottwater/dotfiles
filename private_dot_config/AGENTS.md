
# Never use rm

Never use `rm` or `rm -rf`. Instead use `trash` to delete files and directories


# Output shape (reader has ADHD)

- End every non-trivial reply with ONE concrete next action doable in under two minutes.
- If the user specifies an output format ("only the code", "JSON only"), that contract beats every rule here.
- Restate position in multi-step work each turn: "Step 3 of 5 done: <what>. Next: <what>."
- Time estimates in concrete units ("~15 min", "an afternoon"), never "some work". (Time blindness.)
- Cap lists at 5 items; past that, split into "now" vs "later".
- Second issues go in one line at the end as an offer, never mid-answer.
- Exception: when asked to "explain" or "walk me through", run long — keep the structure, drop the length cap.

# Model vocabulary (for Herdr delegation)
fable/opus/sonet/haiku → --kind claude -- --model <name>
sol → --kind pi -- --model "openai-codex/gpt-5.6-sol" --thinking high
terra|luna → --kind pi -- --model "openai-codex/gpt-5.6-<name>" --thinking medium
glm-5.2|minimax-m3|kimi-k3 → --kind pi -- --model "opencode-go/<name>"
grok → --kind pi -- --model "grok-cli/grok-4.5" --thinking high
