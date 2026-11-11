extends Node
## Global signal bus. Systems emit and listen here instead of referencing
## each other directly, so they stay decoupled. Add signals as systems need them.

# --- Laws ---
signal laws_changed
signal definition_changed(term: StringName)

# --- Station & devices ---
signal device_changed(device: Node)

# --- Crew & orders ---
signal order_received(order: Variant)

# --- Shift ---
signal shift_started
signal shift_ended(outcome: StringName)
