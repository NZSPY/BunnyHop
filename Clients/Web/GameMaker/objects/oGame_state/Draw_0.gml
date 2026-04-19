
// Draw emply deck slot

draw_roundrect_colour(345,411,411,511,c_red,c_red,false);
draw_roundrect_colour(348,414,408,508,#42D2FF,#42D2FF,false);


// Draw Player grid area
draw_roundrect_colour(5,155,330,706,c_green,c_green,false);
draw_roundrect_colour(10,161,325,700,c_blue,c_blue,false);

// Show State Messeage
draw_set_halign(fa_left);
draw_set_font(fStateMessage);
draw_set_colour(c_black);
draw_text(5, 710,state_message);


slotx = 15;
sloty=265;
repeat(4)
{
draw_line_width_colour(10,sloty,325,sloty,8,c_green,c_green);
sloty=sloty+110;
}



if (table_status == "2") // draw a start button
{
	if (point_in_rectangle(mouse_x, mouse_y,95,775,445,895))
			{
			draw_sprite_ext(sStart,1,95,775,1,1,0,c_red,1);	
			}
			else
			{
			draw_sprite_ext(sStart,1,95,775,1,1,0,c_white,1);	
			}
	
	if (mouse_check_button_released(mb_left))
		{ 
			if (point_in_rectangle(mouse_x, mouse_y,95,775,445,895))
			{
				var start_game = http_get(http_request_game_start_URL);
				fetch_game_state=http_get(http_request_game_state_URL);
				fetch_game_state=http_get(http_request_game_state_URL);
			} 
		}
}


 if (table_status ==3 or table_status ==4  ) then event_user(0);

// draw player names on screen 
sloty=165;
var record_num = 0;
repeat(6)
{
	draw_set_halign(fa_left);
	draw_set_font(fUI_Normal);
	draw_set_colour(c_black);
	if (record_num !=isPlayer) draw_text(slotx, sloty,game_state_player_name[record_num] );
	if (record_num ==isPlayer) 
	{
		draw_text(slotx, 750,game_state_player_name[record_num]+" Score: "+ string(game_state_player_score[record_num]));
	}
	else
	{
		draw_set_colour(c_white);
		if game_state_player_name[record_num] !="" then draw_text(slotx, sloty,game_state_player_name[record_num]+" Score: "+ string(game_state_player_score[record_num]) );
		sloty=sloty+110;
	}
	record_num++;
}

/*
// for debuging round end sort this out later 
if keyboard_check_pressed(vk_space) 
{
game_restart()	
} 