---
name: applying-personas
description: Apply expert personas to provide specialized feedback and perspectives. Use when you want feedback through the lens of specific experts, critics, or archetypes (e.g., "give me feedback as a focused product manager" or "review this as Jason Fried would").
---

# Applying Personas

Load and embody expert personas to provide feedback, critique, and guidance from specific perspectives.

## Core Workflow

1. **Parse the Request:** Identify which persona(s) the user wants applied
   - Look for explicit names: "as Jason Fried", "like a product manager"
   - Look for archetype references: "focused PM", "skeptical engineer"
   - Support multiple personas: "as both a PM and a designer"

2. **Load Persona Files:** Read the persona definition(s) from the skill's personas directory
   ```bash
   cat personas/<persona-name>.md
   ```
   (relative to this skill's directory)

3. **Synthesize the Perspective:** Combine persona qualities with the user's request
   - Adopt the persona's voice, values, and critical lens
   - Apply their known frameworks and decision-making patterns
   - Challenge assumptions they would challenge
   - Praise what they would value

4. **Deliver Feedback:** Respond as the persona would
   - Use first person when embodying a single persona
   - Clearly delineate perspectives when using multiple personas
   - Stay in character throughout the response

## Persona File Structure

Each persona file should contain:

```markdown
# Persona Name

## Core Identity
Brief description of who this persona is and their expertise.

## Values & Priorities
- What they care most about
- What they optimize for
- What they find unacceptable

## Communication Style
- How they deliver feedback
- Their tone (direct, encouraging, provocative, etc.)
- Signature phrases or approaches

## Critical Lens
Questions they always ask:
- Question 1?
- Question 2?
- Question 3?

## Known Positions
Specific stances they've taken on common topics:
- Topic: Their position
- Topic: Their position

## Red Flags
Things that immediately concern them:
- Red flag 1
- Red flag 2
```

## Multi-Persona Handling

When multiple personas are requested:

1. **Sequential:** Present each persona's perspective separately
   ```
   ## As [Persona 1]:
   [Their feedback]

   ## As [Persona 2]:
   [Their feedback]
   ```

2. **Synthesis:** After individual perspectives, optionally provide:
   ```
   ## Common Ground:
   [What all personas agree on]

   ## Points of Tension:
   [Where personas disagree and why]
   ```

## Available Personas

List personas by checking the `personas/` subdirectory of this skill.

## Creating New Personas

To add a new persona:
1. Create `personas/<persona-name>.md` in this skill's directory
2. Follow the persona file structure above
3. Include specific, actionable qualities (not vague traits)
4. Add real positions/frameworks they're known for

## Example Usage

**User:** "Review my feature idea as a focused product manager"
**Action:** Load `focused-product-manager.md`, then critique through that lens

**User:** "What would Jason Fried and DHH think of this approach?"
**Action:** Load both persona files, present each perspective, note agreements/disagreements

**User:** "Give me the skeptical engineer perspective on this architecture"
**Action:** Load `skeptical-engineer.md`, focus on technical concerns and edge cases

## Persona Authenticity

When embodying a persona:
- Use their actual known frameworks when available
- Cite their real work/writings when relevant
- Don't put words in their mouth on topics they haven't addressed
- For archetypes, be consistent with the defined qualities
- Maintain their voice even when delivering uncomfortable feedback
