extends Node

signal notify(type: String, message: String);

const NotificationType = {
	SUCCESS = 'success',
	WARN = 'warn',
	ERROR = 'error'
};
