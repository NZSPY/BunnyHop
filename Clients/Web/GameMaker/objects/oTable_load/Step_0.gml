if (mouse_check_button_released(mb_left))
{ 
if (point_in_rectangle(mouse_x, mouse_y,115,155,290,180))
{

	msg = get_string_async("What's your name?", "Lorenzo");
	global.name_set = true

} 
}


	
if (string_length(global.player_name) > 10 && global.name_set)
{
    global.player_name = string_copy(global.player_name, 1, 10);
}