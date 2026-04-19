
// get the lastest state from the server evey second unless it's the main players then only get every 10 seconds 
if (game_state_player_status[isPlayer]==0) then turn_timer=60;
if (game_state_player_status[isPlayer]==1) 
{

	timer--;
	turn_timer--;
	if timer <=0 
	{
	fetch_game_state=http_get(http_request_game_state_URL);
	timer=10;
	}
}
else
{
	fetch_game_state=http_get(http_request_game_state_URL);
}

if (turn_timer<=0) // auto play the player if they haven't played in 60 seconds
{
	var move = string_copy(game_state_player_valid_moves[isPlayer], string_length(game_state_player_valid_moves[isPlayer]), 1)
	var Do_Move = http_get(http_request_Do_Move_URL+move);
	fetch_game_state=http_get(http_request_game_state_URL);	
	turn_timer=60;
} 



alarm[0] = game_get_speed(gamespeed_fps)*1;