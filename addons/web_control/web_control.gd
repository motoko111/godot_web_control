extends Control
class_name WebControl

## Controlの領域に指定のhtmlを埋め込む

@export var div_id:String = "custom-div"
@export var div_z_index:int = 1000
@export var background_color:Color = Color(0,0,0,0)
@export_multiline var html:String = ""
@export_multiline var init_javascript:String = ""

var _godot_external:JavaScriptObject = null
var _js_callbacks:Dictionary[String,JavaScriptObject] = {}

func _ready() -> void:
	if !_is_web():
		return
	item_rect_changed.connect(_resize)
	get_viewport().size_changed.connect(_resize)
	setup(html,init_javascript)
	
func _exit_tree() -> void:
	if !_is_web():
		return
	JavaScriptBridge.eval("""
	(function(){
		let div = document.getElementById('%s');
		if(div)
		{
			div.parentNode.removeChild(div);
		}
	})();
	""" % [div_id])
	
func _process(delta: float) -> void:
	_update_div()
	
func _resize():
	_update_div()

func _is_web() -> bool:
	return OS.get_name() == "Web"
	
func _setup_godot_external():
	if !_godot_external:
		JavaScriptBridge.eval("""
		(function(){
			if(!window.godot_external)
			{
				window.GodotFunctions = {}
				window.godot_external = {}
				window.godot_external.addGodotFunction = (name,func) => {
					window.GodotFunctions[name] = func
				}
			}
		})();
		""")
		_godot_external = JavaScriptBridge.get_interface("godot_external")
		for key in _js_callbacks.keys():
			add_js_func(key,_js_callbacks[key])
	
func add_js_func(js_func_name,js_callback):
	if not(js_callback is JavaScriptObject):
		push_error("[WebControl::add_js_func] [%s] js_callback is not JavaScriptObject" % [js_func_name])
		return
	if !_js_callbacks.has(js_func_name):
		_js_callbacks[js_func_name] = js_callback
	_godot_external.addGodotFunction(js_func_name, js_callback)
	
func setup(_html:String,_init_js:String):
	if !_is_web():
		return
	
	_setup_godot_external()
	
	JavaScriptBridge.eval("""
	(function(){
		let div = document.getElementById('%s');
		if(!div)
		{
			div = document.createElement('div');
			div.id = '%s';
			document.body.appendChild(div);
			console.log("create div " + div.id);
		}
		div.style.position = 'absolute';
		div.style.zIndex = '%d';
		div.style.boxSizing = 'border-box';
		div.style.background = '#%s';
		div.innerHTML = `%s`;
	})();
	""" % [div_id, div_id, div_z_index,background_color.to_html(), _html])
	
	JavaScriptBridge.eval(_init_js)

func _update_div():
	if !_is_web():
		return
	
	var grect: Rect2 = get_global_rect()
	var screen_size = get_viewport_rect().size
	
	# このUIの領域が画面上の何割の位置か計算
	var res:Rect2 = Rect2()
	res.position.x = grect.position.x / screen_size.x
	res.position.y = grect.position.y / screen_size.y
	res.size.x = grect.size.x / screen_size.x
	res.size.y = grect.size.y / screen_size.y
	
	# 表示/非表示 切り替え
	var display := "none"
	if is_visible_in_tree():
		display = "block"
	
	# 指定elementをUIの領域分の大きさに変更
	JavaScriptBridge.eval("""
	(function(){
	  let div = document.getElementById('%s');
	  let canvas = document.getElementById('canvas');
	  if(!div || !canvas) return;

	  let cbr = canvas.getBoundingClientRect();

	  let left = cbr.left + (%f) * cbr.width;
	  let top  = cbr.top + (%f) * cbr.height;

	  div.style.left   = left + 'px';
	  div.style.top    = top + 'px';
	  div.style.width  = (%f) * cbr.width + 'px';
	  div.style.height = (%f) * cbr.height + 'px';
	  div.style.display = `%s`;
	})();
	""" % [div_id, res.position.x, res.position.y, res.size.x, res.size.y, display])
