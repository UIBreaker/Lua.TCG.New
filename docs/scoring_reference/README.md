# Scoring rhythm reference

The user's FFF2.mp4 is a 4.63-second visual reference: cards arrive in a flowing sequence, each contributing card gives one soft lift, and its addition briefly appears above it. The reference is used for pacing and readability, not for copying its artwork, UI or scoring rules.

This game's version retains continental art, antique-gold frames, cyan damage, crimson enhancement, gold Aura, SPN and hand-specific attacks. Cards now use a damped lift/tilt rather than rapid jitter. Contributions stay beside their source with short outlined labels; a tiny colored energy mote travels toward the appropriate counter. Repeated contributions replace the previous label in the same row, and the effect queue is capped. The duplicate card bonus pill is removed.

Counters interpolate with a smooth start and stop and remain inside the calculator's exact before/after values. Source triggers have a readable hold and shorter gaps. Multiplication gets a brief anticipation beat. Final Aura rises smoothly, settles on the authoritative result, then converts to the existing attack. The information panel distinguishes forming/charging/ready Aura and adds a thin gold sequence-progress trace. Damage still occurs exactly once at impact; speed settings and enemy-first turns retain their behavior.

Validation: `lua tests/scoring_presentation_smoke.lua` checks real hands, modifier/SPN contributions, bounded effects, no counter overshoot, 30/60/120/144 FPS, normal/fast, large scores, one impact and settled health. `lovec.exe . --test-scoring-feel` checks actual rendering/input/HP lifecycle and the isolated lab. Its fixture now supplies an equipment ID and waits for fast enemies before expecting the scoring sequence.
