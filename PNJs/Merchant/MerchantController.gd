extends CitizenController
class_name MerchantController

func _ready():
	super();

func _init_params_action(params_to_modify: Dictionary, action: Action) -> Dictionary:
	params_to_modify = super._init_params_action(params_to_modify, action);
	if action is TradeAction:
		params_to_modify = {
			'start_position': global_position
		};
	return params_to_modify;
	
