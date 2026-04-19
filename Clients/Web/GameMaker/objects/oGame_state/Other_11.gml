// Draw the main human player

// Override state message if player is waitign for a new round to start 
if (game_state_player_status[isPlayer]==4)
{
draw_set_halign(fa_left);
draw_set_font(fUI_Bold);
draw_set_colour(c_black);
draw_text(5, 890,"Waiting for other players to rejoin the table, for the next round");
}
		
// Draw each card on screen
		var card_offset_step = round(440/(game_state_player_number_of_cards[isPlayer]-1));
		if card_offset_step>=75 then card_offset_step=75;
		var card_slot = CARD_1X-4;
		var card_index = 1;

repeat(game_state_player_number_of_cards[isPlayer])
	{
		var num = real(string_char_at(game_state_player_hand_summary[isPlayer], card_index))
		display_player_card[card_index] = instance_create_depth(card_slot,CARD_MAINPLAYERY,-1,oCard,  {number: num,  size: "Big"});
		// Check if card is being slected 
		if (point_in_rectangle(mouse_x, mouse_y,display_player_card[card_index].x,display_player_card[card_index].y,display_player_card[card_index].x+72,display_player_card[card_index].y+101)
		and game_state_player_status[isPlayer]==1 and string_contains(game_state_player_valid_moves[isPlayer],num))
		{
			display_player_card[card_index].selected=true;
		}
		card_slot+=+card_offset_step
		card_index ++
	}
	

		
if (game_state_player_status[isPlayer]==1) 
	{
// draw box around the player if they is active and show fold button if fold is a valid move
		draw_roundrect_colour(5,745,535,890,c_red,c_red,false);	
		draw_roundrect_colour(7,747,533,888,#42D2FF,#42D2FF,false);
		draw_set_halign(fa_right);
	    draw_set_font(fUI_Normal);
	    draw_set_colour(c_black);
		draw_text(530, 750,"it's your turn now");
		
		if (string_contains(game_state_player_valid_moves[isPlayer],"F"))
			{
			if (point_in_rectangle(mouse_x, mouse_y,150,895,375,950))
				{
					draw_sprite_ext(sFold,1,150,895,0.75,0.40,0,c_red,1);	
				}
			else
				{
					draw_sprite_ext(sFold,1,150,895,0.75,0.40,0,c_white,1);	
				}
			}
	
			
	// display the count down timer to make a move 
	draw_set_halign(fa_right);
	draw_set_font(fCountdown);
	draw_set_colour(c_black); 
	if turn_timer <= 15 then draw_set_colour(c_red);
	draw_text(535, 900, string(turn_timer));


	
// draw a "draw" button if it's a vaild move	
	if string_contains(game_state_player_valid_moves[isPlayer],"D")
	{
	if (point_in_rectangle(mouse_x, mouse_y,337,640,517,695))
				{
					draw_sprite_ext(sDraw,1,337,640,0.65,0.40,0,c_red,1);	
				}
			else
				{
					draw_sprite_ext(sDraw,1,337,640,0.65,0.40,0,c_white,1);	
				}
	}			

// Light up bunny hop card pass options
		card_index = 1
		repeat(game_state_player_number_of_cards[isPlayer])
		{
			if (display_player_card[card_index].number==9
			and (string_contains(game_state_player_valid_moves[isPlayer],"B")
				or string_contains(game_state_player_valid_moves[isPlayer],"H")
				or string_contains(game_state_player_valid_moves[isPlayer],"N")
				or string_contains(game_state_player_valid_moves[isPlayer],"J")
				or string_contains(game_state_player_valid_moves[isPlayer],"M")
				or string_contains(game_state_player_valid_moves[isPlayer],"K"))
			)
			{
				display_player_card[card_index].bunnyed=true;
				draw_set_halign(fa_right);
	    draw_set_font(fUI_Normal);
	    draw_set_colour(c_black);
				draw_text(530, 872,"Select another player to hop to!");
				break;
			}
		card_index ++
		}
			
// if the player clicks on something figure out what they want to do 
		if mouse_check_button_released(mb_left)  
			{ 
				if ( (point_in_rectangle(mouse_x, mouse_y,345,411,411,511) or point_in_rectangle(mouse_x, mouse_y,337,650,517,705))  and string_contains(game_state_player_valid_moves[isPlayer],"D"))  // check to see if player clicks the draw deck or draw button and drawing is a valid move
					{
						var Do_Move = http_get(http_request_Do_Move_URL+"D");
						fetch_game_state=http_get(http_request_game_state_URL);		
						turn_timer=60; 
					} 
				if (point_in_rectangle(mouse_x, mouse_y,150,895,375,950) and string_contains(game_state_player_valid_moves[isPlayer],"F")) // check to see if player clicks the fold button and folding  is a valid move
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
	   // show folded sprite if the player is folded and game playing 

		if (game_state_player_status[isPlayer]==2 and table_status ==3 ) 
		{
			var player_folded = instance_create_depth(FOLDED_MAINPLAYERX,FOLDED_MAINPLAYERY,-2,oFolded,  {size:   "Big"});
		}
	 // show winner sprite if the player is have won  and game is on results status
	if (game_state_player_winner[isPlayer]) 
		{
			var player_folded = instance_create_depth(FOLDED_MAINPLAYERX,FOLDED_MAINPLAYERY,-2,oWinner,  {size:   "Big"});
		}
	
		// Show the Cat token if player has it
		if (game_state_player_has_cat[isPlayer])
		{
			var cat_display = instance_create_depth(CATSPOT_MAINPLAYERX,CATSPOT_MAINPLAYERY,-3,oCardCat);	
		}

		if (string_contains(game_state_player_valid_moves[isPlayer],"R") and game_state_player_status[isPlayer]!=4)
			{
				var frame=0
		if string_contains(state_message,"final")then frame=1
			if (point_in_rectangle(mouse_x, mouse_y,100,890,421,950))
				{
					draw_sprite_ext(sContinue,frame,100,890,0.75,0.40,0,c_red,1);	
				}
			else
				{
					draw_sprite_ext(sContinue,frame,100,890,0.75,0.40,0,c_white,1);	
				}
			}
		if mouse_check_button_released(mb_left)  
			{ 
					if (point_in_rectangle(mouse_x, mouse_y,100,890,421,950) and string_contains(game_state_player_valid_moves[isPlayer],"R")) // clicked on the Continue button 
				{
					var Do_Move = http_get(http_request_Do_Move_URL+"R");
					fetch_game_state=http_get(http_request_game_state_URL);		
				}	
					
			}
			
			if game_state_player_status[isPlayer]==5 then game_restart();
			
			