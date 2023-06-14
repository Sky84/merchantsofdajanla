extends Action
class_name TradeAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	
	on_action_finished.emit(id);


