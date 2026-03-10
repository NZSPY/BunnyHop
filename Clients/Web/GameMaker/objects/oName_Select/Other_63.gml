var _id = ds_map_find_value(async_load, "id");
if (_id == msg)
{
    if (ds_map_find_value(async_load, "status"))
    {
        if (ds_map_find_value(async_load, "result") != "")
        {
            global.player_name = ds_map_find_value(async_load, "result");
        }
    }
}