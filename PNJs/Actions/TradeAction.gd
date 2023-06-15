extends Action
class_name TradeAction

var navigation_agent: NavigationAgent3D;

func execute(params: Dictionary) -> void:
	print("trading")
	#on_action_finished.emit(id, null);


