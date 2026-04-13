
// Get list of avalaible game tables and thier status
if (async_load[? "id"] == http_request_table_list)
{
	
	if(ds_map_find_value(async_load,"status") == 0 )
	{
		var json =ds_map_find_value(async_load, "result");
		var data = json_parse(json);

// load game table information into table arrays
 var record_num=0;
 
repeat(array_length(data))

{

       table_id_array[record_num] = data[record_num].t;
       table_name_array[record_num] = data[record_num].n;
       table_current_players_array[record_num] = data[record_num].p;
       table_max_players_array[record_num] = data[record_num].m;
       table_status_array[record_num] = data[record_num].s;
	   
	   switch (table_status_array[record_num])
	   {
	   case 0:
	   table_status_array[record_num]="Empty"
	   selectable[record_num]=true
	   break;
	   
	   case 1:
	   table_status_array[record_num]="Full"
	   selectable[record_num]=false
	   break;
	   
	   case 2:
	   table_status_array[record_num]="Waiting"
	   selectable[record_num]=true
	   break;
	   
	   case 3:
	   table_status_array[record_num]="Playing"
	   selectable[record_num]=false
	   break;
	   
	   case 4:
	   table_status_array[record_num]="Round Over"
	   selectable[record_num]=false
	   break;
	   
	   case 5:
	   table_status_array[record_num]="Game Over"
	   selectable[record_num]=false
	   break;
	   }
	   
	   record_num++;
}
		
	}
	else
	{
	show_message("Lost conection to server");
	game_end();
		
	}
}

// Join a table 
if (async_load[? "id"] == http_request_join_table)
{
    var _status = async_load[? "status"];
    var _r_str = (_status == 0) ? async_load[? "result"] : "null";

		// show_message(_r_str);
		
		room_goto(Game_Screen);
		
}