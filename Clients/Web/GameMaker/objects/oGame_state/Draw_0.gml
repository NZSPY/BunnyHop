
// Draw emply deck slot

draw_roundrect_colour(345,411,411,511,c_red,c_red,false);
draw_roundrect_colour(348,414,408,508,#42D2FF,#42D2FF,false);


// Draw Player grid area
draw_roundrect_colour(5,185,330,737,c_green,c_green,false);
draw_roundrect_colour(10,191,325,730,c_blue,c_blue,false);

sloty=295;
repeat(4)
{
draw_line_width_colour(10,sloty,325,sloty,8,c_green,c_green);
sloty=sloty+110;
}

slotx = 15;
sloty = 160;

draw_set_halign(fa_left);
draw_set_font(fUI_Normal);
draw_set_colour(c_white);


draw_text(slotx, sloty,state_message);

if (table_status =2) 
{
	draw_text(355, 450,"START");
	
	if (mouse_check_button_released(mb_left))
		{ 
			if (point_in_rectangle(mouse_x, mouse_y,345,411,411,511))
			{
				var start_game = http_get(http_request_game_start_URL);
				fetch_game_state=http_get(http_request_game_state_URL);
			} 
		}
}



sloty=195;

var record_num = 0;



repeat(6)
{
// Draw each players state information 

if (game_state_player_name[record_num] <> "" && isPlayer<>record_num)
{
draw_text(slotx, sloty,game_state_player_name[record_num] );
// draw_text(slotx, sloty+12, game_state_player_status[record_num]);
// draw_text(slotx, sloty+24, game_state_player_number_of_cards[record_num]);
// draw_text(slotx, sloty+36, game_state_player_hand_summary[record_num]);
// draw_text(slotx, sloty+48, game_state_player_valid_moves[record_num]);
sloty=sloty+110;
}

if (record_num=isPlayer) 
{
	draw_text(slotx, 750,game_state_player_name[record_num] );
}
record_num++;

}

draw_sprite_ext(sCardBack,0,CARD_1X,global.cardy_player[1],0.15,0.15,0,c_white,1); // player 1
draw_sprite_ext(sCardBack,0,CARD_1X,global.cardy_player[2],0.15,0.15,0,c_white,1); // player 2
draw_sprite_ext(sCardBack,0,CARD_1X,global.cardy_player[3],0.15,0.15,0,c_white,1); // player 3
draw_sprite_ext(sCardBack,0,CARD_1X,global.cardy_player[4],0.15,0.15,0,c_white,1); // player 4
draw_sprite_ext(sCardBack,0,CARD_1X,global.cardy_player[5],0.15,0.15,0,c_white,1); // player 5

draw_sprite_ext(sCardDog,0,CARD_1X,CARD_MAINPLAYERY,0.2,0.2,0,c_white,1); // Main Player




draw_sprite_ext(sCardCat,0,CATSPOT_HORIZONAL,global.catspot_player[1],0.15,0.15,0,c_white,1); // player 1
draw_sprite_ext(sCardCat,0,CATSPOT_HORIZONAL,global.catspot_player[2],0.15,0.15,0,c_white,1); // player 2
draw_sprite_ext(sCardCat,0,CATSPOT_HORIZONAL,global.catspot_player[3],0.15,0.15,0,c_white,1); // player 3
draw_sprite_ext(sCardCat,0,CATSPOT_HORIZONAL,global.catspot_player[4],0.15,0.15,0,c_white,1); // player 4
draw_sprite_ext(sCardCat,0,CATSPOT_HORIZONAL,global.catspot_player[5],0.15,0.15,0,c_white,1); // player 5

draw_sprite_ext(sCardCat,0,CATSPOT_MAINPLAYERX,CATSPOT_MAINPLAYERY,0.15,0.15,0,c_white,1); // Main Player






if (table_status= 3 && draw_deck > 0) // Draw the cards on the table is the table satus is playing 
{

if (draw_deck >0)	// Draw the main deck if it has cards left
	{
	draw_sprite_ext(sCardBack,0,342,410,0.2,0.2,0,c_white,1);
	draw_set_halign(fa_left);
	draw_set_font(fUI_Bold);
	draw_set_colour(c_black);
	draw_text(370, 515,draw_deck);
	}
	
if (discard_pile <>"")  // Show the top most card in the discard pile 
	{
		
	draw_sprite_ext(sCardDog,0,DISCARD_HOMEX,DISCARD_HOMEY,0.2,0.2,0,c_white,1); // add some wiggle to this X+20 Y+10
	}
	
	if (cat_status="B")
	{
	draw_sprite_ext(sCardCat,1,CATSPOT_HOMEX,CATSPOT_HOMEY,0.15,0.15,0,c_white,1);	
	}

}

