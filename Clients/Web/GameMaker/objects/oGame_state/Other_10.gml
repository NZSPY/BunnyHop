

sloty=195;
var record_num = 0;


repeat(6)
{
// Draw each players state information 

if (game_state_player_name[record_num] != "" && isPlayer != record_num)
{

	//debug deplay remove later
	draw_text(slotx+320, sloty+12, game_state_player_status[record_num]);
	draw_text(slotx+320, sloty+24, game_state_player_number_of_cards[record_num]);
	draw_text(slotx+320, sloty+36, game_state_player_hand_summary[record_num]);
	draw_text(slotx+320, sloty+48, game_state_player_valid_moves[record_num]);

		if (game_state_player_status[record_num] ==1) // draw box over the active player
			{
				draw_roundrect_colour(slotx-5,sloty-6,325,sloty+96,c_red,c_red,false);	
			}

		var card_offset_step = round(240/(game_state_player_number_of_cards[record_num]-1))
		if card_offset_step<5 then card_offset_step=5; // smallest the card gap can be need to add some other code to deal with this latter
		var card_slot =CARD_1X
		
		repeat(game_state_player_number_of_cards[record_num])
		{
	
		 var display_other_player_card = instance_create_depth(card_slot,sloty+16,-1,oCard, {number: 10, size: "Small"});
		 // draw_text(card_slot+20,sloty+20, record_num);  // use for debugging 
		 card_slot+=+card_offset_step
		 
		
		}
		
		if (game_state_player_status[record_num]==2) // player is folded
		{
			var player_folded = instance_create_depth(FOLDED_HORIZONAL,sloty+20,-2,oFolded, {size: "Small"});
		}
 sloty=sloty+110;
}

if (isPlayer==record_num) 
{


		//debug deplay remove later
		draw_text(slotx+400, 640, game_state_player_status[record_num]);
		draw_text(slotx+400, 650, game_state_player_number_of_cards[record_num]);
		draw_text(slotx+400, 660, game_state_player_hand_summary[record_num]);
		draw_text(slotx+400, 670, game_state_player_valid_moves[record_num]);
		
		var card_offset_step = round(440/(game_state_player_number_of_cards[record_num]-1))
		var card_slot = CARD_1X-4
		var card_index = 1
		repeat(game_state_player_number_of_cards[record_num])
		{
		var num = real(string_char_at(game_state_player_hand_summary[record_num], card_index))
		 display_player_card[card_index] = instance_create_depth(card_slot,CARD_MAINPLAYERY,-1,oCard,  {number: num,  size: "Big"});
		if (point_in_rectangle(mouse_x, mouse_y,display_player_card[card_index].x,display_player_card[card_index].y,display_player_card[card_index].x+72,display_player_card[card_index].y+101) and game_state_player_status[record_num]==1 and string_contains(game_state_player_valid_moves[record_num],num)) then display_player_card[card_index].selected=true;
		 card_slot+=+card_offset_step
		 card_index ++
		}
		
		if (game_state_player_status[record_num]==1) // draw box around the player if they is active and fold button
		{
			draw_roundrect_colour(5,745,535,890,c_red,c_red,false);	
			draw_roundrect_colour(7,747,533,888,#42D2FF,#42D2FF,false);
			if (point_in_rectangle(mouse_x, mouse_y,150,895,375,950))
			{
			draw_sprite_ext(sFold,1,150,895,0.75,0.40,0,c_red,1);	
			}
			else
			{
			draw_sprite_ext(sFold,1,150,895,0.75,0.40,0,c_white,1);	
			}
			
			if mouse_check_button_released(mb_left)  // if the player is active and clicks on something figure out what they want to do 
				{ 
				if (point_in_rectangle(mouse_x, mouse_y,345,411,411,511) and string_contains(game_state_player_valid_moves[record_num],"D")) // check to see if player clicks the draw deck and drawing is a valid move
					{
						var Do_Move = http_get(http_request_Do_Move_URL+"D");
						fetch_game_state=http_get(http_request_game_state_URL);	
						
					} 
				if (point_in_rectangle(mouse_x, mouse_y,150,895,375,950) and string_contains(game_state_player_valid_moves[record_num],"F")) // check to see if player clicks the fold button and folding  is a valid move
					{
						var Do_Move = http_get(http_request_Do_Move_URL+"F");
						fetch_game_state=http_get(http_request_game_state_URL);	
					} 
				card_index = 1	
				repeat(game_state_player_number_of_cards[isPlayer])	
					{
					if (display_player_card[card_index].selected)
						{
							var Move_Text = string(display_player_card[card_index].number)
	                        var Do_Move = http_get(http_request_Do_Move_URL+Move_Text);
							fetch_game_state=http_get(http_request_game_state_URL);	
						}
					card_index ++	
					}
				}
					
		}



		if (game_state_player_status[record_num]==2) // player is folded
		{
			var player_folded = instance_create_depth(FOLDED_MAINPLAYERX,FOLDED_MAINPLAYERY,-2,oFolded,  {size:   "Big"});
		}
	


}
//sloty=sloty+110;
record_num++
}




if (draw_deck >0)	// Draw the main deck if it has cards left
		{
		main_deck = instance_create_depth(342,410,-1,oCard, {number: 10, size: "Big"});
		draw_set_halign(fa_left);
		draw_set_font(fUI_Bold);
		draw_set_colour(c_black);
		draw_text(370, 515,draw_deck);
		if (point_in_rectangle(mouse_x, mouse_y,345,411,411,511) and game_state_player_status[isPlayer]==1 ) then main_deck.selected=true;
		}
	
if (discard_pile <> "")  // Show the top most card in the discard pile 
	{
		var real_discard_pile = real(discard_pile);
		var display_discard_pile = instance_create_depth(DISCARD_HOMEX+10,DISCARD_HOMEY+5,-1,oCard, {number: real_discard_pile , size: "Big"});
		// add some wiggle to this in the future X+20 Y+10		
	}
	
if (cat_status="B") // Show cat in the basket 
	{
		draw_sprite_ext(sCardCat,1,CATSPOT_HOMEX,CATSPOT_HOMEY,0.15,0.15,0,c_white,1);	
	}


