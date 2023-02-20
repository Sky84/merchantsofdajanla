extends Node

func _get_one_item_of(slot: Dictionary):
	var next_current = slot.duplicate(true);
	next_current.amount = 1;
	return next_current;

func _pick_one_from(slot: Dictionary):
	var slot_amount = slot.amount;
	if slot_amount > 1:
		slot.amount = slot_amount - 1;
	else:
		slot = {};
	return slot;
