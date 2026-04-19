// draw all  player but the main human player 

sloty=165;
var record_num = 0;




repeat(6)
{
// Draw each players state information 

if (game_state_player_name[record_num] != "" && isPlayer != record_num)
{
    
		if (game_state_player_status[record_num] ==1) // draw box over the active player
			{
				draw_roundrect_colour(slotx-5,sloty-6,325,sloty+96,c_red,c_red,false);	
			}
			
		if (point_in_rectangle(mouse_x, mouse_y,slotx-5,sloty-6,325,sloty+96) and string_contains(game_state_player_valid_moves[isPlayer],bunny_hop_flag_check(record_num))) // draw box a player that a Bunny can be passed too
		
			{
				draw_roundrect_colour(slotx-5,sloty-6,325,sloty+96,c_yellow,c_yellow,false);
				if mouse_check_button_released(mb_left)  
				{
					var Do_Move = http_get(http_request_Do_Move_URL+bunny_hop_flag_check(record_num));
					fetch_game_state=http_get(http_request_game_state_URL);
				}
			}
				

		var card_offset_step = round(240/(game_state_player_number_of_cards[record_num]-1))
		if card_offset_step<5 then card_offset_step=5; // smallest the card gap can be need to add some other code to deal with this latter
		if card_offset_step>=40 then card_offset_step=40;
		var card_slot =CARD_1X
		var card_index = 1
		repeat(game_state_player_number_of_cards[record_num])
		{
		 var num = real(string_char_at(game_state_player_hand_summary[record_num], card_index))
		 if table_status == 3 then num =10;
		 var display_other_player_card = instance_create_depth(card_slot,sloty+16,-1,oCard, {number: num, size: "Small"});
		 card_slot+=+card_offset_step
		 card_index ++
		
		}
		// Show the Cat token if player has it
		if (game_state_player_has_cat[record_num])
		{

			var cat_display = instance_create_depth(CATSPOT_HORIZONAL,sloty,-3,oCardCat);	
		}

		
		if (game_state_player_status[record_num]==2 and table_status == 3) // player is folded
		{
			var player_folded = instance_create_depth(FOLDED_HORIZONAL,sloty+20,-2,oFolded, {size: "Small"});
		}
		
			if (game_state_player_winner[record_num]) // player is the round winner
		{
			var player_folded = instance_create_depth(FOLDED_HORIZONAL,sloty+20,-2,oWinner, {size: "Small"});
		}
 sloty=sloty+110;

}

if (isPlayer==record_num) then event_user(1)
record_num++
}




if (table_status ==3)
{

if (draw_deck >0  )	// Draw the main deck if it has cards left
		{
		main_deck = instance_create_depth(342,410,-1,oCard, {number: 10, size: "Big"});
		draw_set_halign(fa_left);
		draw_set_font(fUI_Bold);
		draw_set_colour(c_black);
		draw_text(370, 515,draw_deck);
		if (point_in_rectangle(mouse_x, mouse_y,345,411,411,511) and game_state_player_status[isPlayer]==1 and string_contains(game_state_player_valid_moves[isPlayer],"D")) then main_deck.selected=true;
		}
	
if (discard_pile != "" )  // Show the top most card in the discard pile 
	{
		var real_discard_pile = real(discard_pile);
		if real_discard_pile !=11 
			{
			var display_discard_pile = instance_create_depth(DISCARD_HOMEX+10,DISCARD_HOMEY+5,-1,oCard, {number: real_discard_pile , size: "Big"});
			}		
	}
	
if (cat_status="7" ) // Show cat in the basket 
	{
		draw_sprite_ext(sCardCat,1,CATSPOT_HOMEX,CATSPOT_HOMEY,0.15,0.15,0,c_white,1);	
	}

}
