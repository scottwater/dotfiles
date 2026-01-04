---
name: nano-banana-prompts
description: Generate professional prompts for Nano Banana Pro image generation. Use when the user wants to create images, thumbnails, infographics, edit photos, generate character-consistent content, create storyboards, or any visual asset using Nano Banana Pro. Transforms vague requests into detailed, effective prompts following Nano Banana Pro's "thinking model" best practices.
---

# Nano Banana Pro Prompt Generator

Generate prompts that leverage Nano Banana Pro's reasoning capabilities. The model understands intent, physics, and composition—treat it like briefing a creative director, not tagging keywords.

## Golden Rules

1. **Natural language, not tag soup** — Full sentences with proper grammar, not "cool car, neon, 8k"
2. **Edit, don't re-roll** — For 80%+ correct images, request specific changes conversationally
3. **Provide context** — Include the "why" or "for whom" to guide artistic decisions
4. **Be specific** — Define subject, setting, lighting, mood, and materiality (textures like "brushed steel," "soft velvet")

## Prompt Structure Template

```
[SHOT TYPE]: Wide/Medium/Close-up/etc.
[SUBJECT]: Detailed description with specific attributes
[SETTING]: Environment with lighting and atmosphere
[MOOD/STYLE]: Artistic direction, color palette, era
[CONTEXT]: Purpose/audience (e.g., "for a luxury brand campaign")
[FORMAT]: Aspect ratio if needed (16:9, square, etc.)
```

## Capability-Specific Patterns

### Text & Infographics
- Use "compress" for dense information → visual aids
- Specify style: "polished editorial," "technical diagram," "hand-drawn whiteboard"
- Put exact text in quotes: `Overlay text: "Your Text Here"`

**Example:** "Create a retro 1950s-style infographic about American diners. Include sections for 'The Food,' 'The Jukebox,' and 'The Decor.' All text legible and period-styled."

### Character Consistency (up to 14 reference images)
- State explicitly: "Keep facial features exactly the same as Image 1"
- Describe expression/pose changes while maintaining identity
- For groups: "Keep attire and identity consistent for all characters"

**Example:** "Design a viral thumbnail using the person from Image 1. Face Consistency: Keep facial features exactly the same, but change expression to excited/surprised. Pose on left, pointing right toward [product]. Add bold yellow arrow. Text: 'Done in 3 mins!' with white outline and drop shadow."

### Editing & Restoration
- Semantic instructions—no manual masking needed
- Object removal: "Remove [object] and fill with logical textures matching the environment"
- Colorization: Specify palette and style for manga/B&W photos
- Seasonal/lighting: "Turn to winter, keep architecture exact, add snow"

### Dimensional Translation (2D ↔ 3D)
- Floor plans → 3D interiors: Specify layout (main image + smaller detail shots), style, materials
- Meme conversion: "Turn [meme] into photorealistic 3D render, keep composition identical"

### Storyboards & Sequential Art
- Request images "one at a time" for consistency
- Mandate: "Identity and attire must stay consistent throughout"
- Specify emotional arc: "thrilling with highs and lows, ending happy"

**Example:** "Create a 9-part story featuring [characters] in a luxury commercial. Emotional highs and lows, ending elegantly. Identity and attire consistent throughout. Generate one at a time. 16:9 landscape format."

### Structural Control
- Upload sketches/wireframes to control exact layout
- "Create ad following this sketch"
- For sprites/pixel art: "Fit perfectly into this [N]x[N] grid"

## Quality Modifiers

| Need | Add to prompt |
|------|---------------|
| High resolution | "4K," "suitable for large-format print" |
| Texture detail | Describe imperfections: "visible grain," "subtle scratches" |
| Professional output | Context: "award-winning," "editorial quality," "for [industry] campaign" |

## Prompt Transformation Examples

❌ **Vague:** "sandwich picture"
✅ **Effective:** "A gourmet sandwich photographed for a Brazilian high-end cookbook. Professional plating, shallow depth of field, soft natural lighting. Show texture of toasted artisan bread and glistening ingredients."

❌ **Vague:** "cool car night city"
✅ **Effective:** "A cinematic wide shot of a futuristic sports car speeding through a rainy Tokyo street at night. Neon signs reflect off the wet pavement and the car's metallic chassis. Blade Runner aesthetic, 16:9."

❌ **Vague:** "old woman portrait"
✅ **Effective:** "A sophisticated elderly woman wearing a vintage Chanel-style suit. Studio lighting with soft key light. Expression: quiet confidence. Background: muted cream. For a fashion editorial celebrating timeless elegance."
