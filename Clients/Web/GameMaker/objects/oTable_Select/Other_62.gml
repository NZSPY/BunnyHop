

if (ds_map_find_value(async_load, "id") == request_handle) 
{
	
	if(ds_map_find_value(async_load,"status") == 0 )
	{
		var json =ds_map_find_value(async_load, "result");
		var data = json_parse(json);

// load data into table arrays
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
	   table_status_array[record_num]="Round Over"
	   break;
	   
	   case 1:
	   table_status_array[record_num]="Full"
	   break;
	   
	   case 2:
	   table_status_array[record_num]="Waiting"
	   break;
	   
	   case 3:
	   table_status_array[record_num]="Playing"
	   break;
	   
	   case 4:
	   table_status_array[record_num]="Round Over"
	   break;
	   
	   case 5:
	   table_status_array[record_num]="Game Over"
	   break;
	   }
	   
	   record_num++;
}


		
	}
	else
	{
	show_message("Fail");
		
	}
}