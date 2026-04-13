
// Draw emply deck slot

draw_roundrect_colour(345,411,411,511,c_red,c_red,false);
draw_roundrect_colour(348,414,408,508,#42D2FF,#42D2FF,false);


// Draw Player grid area
draw_roundrect_colour(5,185,330,737,c_green,c_green,false);
draw_roundrect_colour(10,191,325,730,c_blue,c_blue,false);

// Show State Messeage
slotx = 15;
sloty = 160;
draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_white);
draw_text(slotx, sloty,state_message);


sloty=295;
repeat(4)
{
draw_line_width_colour(10,sloty,325,sloty,8,c_green,c_green);
sloty=sloty+110;
}



if (table_status == 2) 
{
	draw_text(355, 450,"START");
	
	if (mouse_check_button_released(mb_left))
		{ 
			if (point_in_rectangle(mouse_x, mouse_y,345,411,411,511))
			{
				var start_game = http_get(http_request_game_start_URL);
				fetch_game_state=http_get(http_request_game_state_URL);
				fetch_game_state=http_get(http_request_game_state_URL);
			} 
		}
}


 if (table_status == 3) then event_user(0);

// draw player names on screen 
sloty=195;
var record_num = 0;
repeat(6)
{
	draw_set_halign(fa_left);
	draw_set_font(fUI_Normal);
	draw_set_colour(c_white);
	if (record_num !=isPlayer) draw_text(slotx, sloty,game_state_player_name[record_num] );
	if (record_num ==isPlayer) 
	{
		draw_text(slotx, 750,game_state_player_name[record_num] );
	}
	else
	{
		draw_text(slotx, sloty,game_state_player_name[record_num] );
		// var display_other_player_card = instance_create_depth(slotx,sloty+10,-1,oCard)  with (display_other_player_card) {number = 10; size  = "Small";};
		sloty=sloty+110;
	}
	record_num++;
}


