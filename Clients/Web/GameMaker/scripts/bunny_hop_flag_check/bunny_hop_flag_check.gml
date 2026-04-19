/// @function       pass the bunnyhop flag and return the numerial vale back
/// @param {int}    Bunny hop player number to check


function bunny_hop_flag_check(argument0)
{

var _number =argument0;
var _flag = "";

switch (_number)
{
	case 0:
		_flag="B";
	break;
	
	case 1:
		_flag="H";
	break;
	
	case 2:
		_flag="N";
	break;
	
	case 3:
		_flag="J";
	break;
	
	case 4:
		_flag="M";
	break;
	
	case 5:
		_flag="K";
	break;
}

return _flag;
}