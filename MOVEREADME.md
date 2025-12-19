--[[
Commentted out for roblox😂
================================================================================
📘 VerseBreak – COMPLETE MOVE SYSTEM README
================================================================================

This document explains the VerseBreak move system in FULL DETAIL.

It is written for:
• New developers on the game
• Combat designers
• Anyone writing character move modules for us

NO prior knowledge is assumed.

================================================================================
1️⃣ CORE DESIGN PHILOSOPHY
================================================================================

-----------------------------------
ONE MOVE INSTANCE AT A TIME
-----------------------------------

At any moment, a player may have:
• ZERO active moves
• OR EXACTLY ONE active move

Never more.

This is ENFORCED at the engine level.

Why?
• prevents animation overlap
• prevents damage stacking exploits
• guarantees deterministic cooldowns
• avoids desync between client/server
• makes debugging sane

If a move needs multiple phases:
→ those phases live INSIDE the SAME move instance.


-----------------------------------
MOVES OWN THEIR OWN LIFECYCLE
-----------------------------------

Moves are NOT fire-and-forget.

A move begins when input is accepted.
A move ENDS ONLY when:

    move:End("Reason")

is called.

If you forget to call move:End():
• the player is locked
• cooldown never starts
• UI never updates
• follow-ups never close

THIS IS INTENTIONAL.
Forgetting to end a move is treated as a BUG.

-----------------------------------
COOLDOWNS START AFTER MOVE END
-----------------------------------

Cooldowns NEVER start on key press.

They start ONLY after:
    move:End()

This guarantees:
• holds don’t start cooldown early
• long animations don’t cheat cooldowns
• interruptions are fair
• follow-ups are honest

================================================================================
2️⃣ CHARACTER MODULE STRUCTURE
================================================================================

Each character module is PURE DATA + LOGIC.

It does NOT:
• track runtime state
• store cooldowns
• manage awakening timers
• touch UI directly

BASIC STRUCTURE:

    return {
        Name = "CharacterName",
        Rarity = "Common",
        Description = "Short description",

        Moves = { ... },
        AwakenedMoves = { ... } -- optional
    }

Keys inside Moves MUST be strings:
"1", "2", "3", "4", "T", "G", "Z"

================================================================================
3️⃣ SIMPLE MOVE (BASE CASE)
================================================================================

Use this when:
• no variants
• no holds
• no follow-ups

Example:

    ["1"] = {
        Name = "Straight Punch",
        Cooldown = 4,

        Action = function(move)
            move:PlayAnim("Punch")
            move:FireVFX("PunchTrail")

            move:After(0.35, function()
                move:DealDamage({
                    Amount = 6,
                    Radius = 4
                })

                move:End("Finished")
            end)
        end
    }

RULES:
• ALWAYS end the move
• Use move:After(), NOT wait()
• Damage happens server-side only

================================================================================
4️⃣ VARIANTS SYSTEM (CORE FEATURE)
================================================================================

Variants allow ONE input to branch into multiple behaviors
WITHOUT starting a new move.

-----------------------------------
AUTOMATIC VARIANT PRIORITY
-----------------------------------

When input is received:

1) R variant (manual override)
2) Air variant (if airborne)
3) Default variant

Only ONE variant executes.

-----------------------------------
VARIANT STRUCTURE
-----------------------------------

    Variants = {
        Default = { ... },
        Air = { ... },
        R = { ... }
    }

Each variant defines:
• Name        → UI display name
• VariantType → UI indicator (Air / R / Ground / Counter etc.)
• Action OR Hold

-----------------------------------
VARIANT EXAMPLE
-----------------------------------

    ["2"] = {
        Name = "Smash",
        Cooldown = 6,

        Variants = {

            Default = {
                VariantType = "Ground",
                Name = "Ground Smash",

                Action = function(move)
                    move:PlayAnim("Smash")
                    move:After(0.5, function()
                        move:DealDamage({ Amount = 7, Radius = 6 })
                        move:End("Done")
                    end)
                end
            },

            Air = {
                VariantType = "Air",
                Name = "Aerial Smash",

                Action = function(move)
                    move:PlayAnim("AerialSmash")
                    move:After(0.45, function()
                        move:DealDamage({ Amount = 8, Radius = 6 })
                        move:End("Done")
                    end)
                end
            },

            R = {
                VariantType = "ManualR",
                Name = "Charged Smash",

                Action = function(move)
                    move:PlayAnim("Charge")
                    move:After(0.8, function()
                        move:DealDamage({ Amount = 12, Radius = 8 })
                        move:End("Done")
                    end)
                end
            }
        }
    }

================================================================================
5️⃣ FOLLOW-UP WINDOWS (PRESS-TWICE / TIMING MECHANICS)
================================================================================

Follow-up windows allow a move to accept ADDITIONAL INPUT
within a strict timing range.

Used for:
• combo continuations
• Black Flash–style timing
• skill-based execution
• press-again mechanics

-----------------------------------
WINDOW PARAMETERS
-----------------------------------

• Id        → unique identifier
• Slot      → which key triggers follow-up
• MinDelay  → earliest allowed trigger
• MaxDelay  → latest allowed trigger
• MaxUses   → how many times it can fire
• OnTrigger → callback

-----------------------------------
BLACK FLASH STYLE EXAMPLE
-----------------------------------

    ["3"] = {
        Name = "Impact Strike",
        Cooldown = 7,

        Action = function(move)
            move:PlayAnim("Strike")

            move:OpenWindow({
                Id = "BlackFlash",
                Slot = "3",
                MinDelay = 0.18,
                MaxDelay = 0.24,
                MaxUses = 1,

                OnTrigger = function(m)
                    m:FireVFX("BlackFlash")
                    m:DealDamage({ Amount = 18, Radius = 6 })
                    m:End("PerfectTiming")
                end
            })

            move:After(0.5, function()
                if move:IsActive() then
                    move:DealDamage({ Amount = 7, Radius = 4 })
                    move:End("NormalHit")
                end
            end)
        end
    }

If the player hits the timing:
→ massive reward

If not:
→ normal outcome

================================================================================
6️⃣ GRAB MOVE EXAMPLE
================================================================================

Grabs are still ONE MOVE.

Example:

    ["T"] = {
        Name = "Neck Grab",
        Cooldown = 9,

        Action = function(move)
            move:PlayAnim("GrabStart")

            local target = move:FindTarget(4)
            if not target then
                move:End("Missed")
                return
            end

            move:WeldTarget(target)

            move:After(0.6, function()
                move:DealDamage({ Amount = 14 })
                move:ReleaseTarget()
                move:End("Thrown")
            end)
        end
    }

================================================================================
7️⃣ HOLD / CHANNEL MOVES
================================================================================

Hold moves remain active while input is held.

Used for:
• beams
• barrages
• charging attacks

-----------------------------------
HOLD STRUCTURE
-----------------------------------

    Hold = {
        MaxTime,
        OnStart,
        OnTick,
        OnEnd
    }

-----------------------------------
HOLD EXAMPLE
-----------------------------------

    ["4"] = {
        Name = "Energy Barrage",
        Cooldown = 8,

        Hold = {
            MaxTime = 2.5,

            OnStart = function(move)
                move:PlayAnim("BarrageLoop")
                move:FireVFX("BarrageStart")
            end,

            OnTick = function(move)
                move:DealDamage({ Amount = 1, Radius = 4 })
            end,

            OnEnd = function(move, reason)
                move:FireVFX("BarrageEnd")
                move:End(reason)
            end
        }
    }

================================================================================
8️⃣ AWAKENING BEHAVIOR
================================================================================

Awakening is ATTRIBUTE-DRIVEN.

• character:GetAttribute("Awakened") == true
• MoveService automatically swaps move tables
• UI automatically updates
• Death clears awakening
• Timers clear awakening

Character modules DO NOT track awakening state.

================================================================================
9️⃣ COMMON MISTAKES (DO NOT DO THESE)
================================================================================

❌ Forgetting move:End()
❌ Using wait() instead of move:After()
❌ Starting cooldowns manually
❌ Overlapping moves
❌ Putting combat logic in UI
❌ Tracking state inside CharacterService

================================================================================
🔟 GOLDEN RULES FOR DEVLOPERS
================================================================================

1) One move at a time
2) Moves end themselves
3) Cooldowns start AFTER end
4) Variants are automatic
5) Follow-ups are timing-based
6) UI never guesses
7) Server is authoritative

If you follow this document,
YOU CANNOT BREAK THE SYSTEM.

================================================================================
END OF README
================================================================================

]]
