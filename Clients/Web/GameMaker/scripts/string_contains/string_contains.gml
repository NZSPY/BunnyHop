/// @func string_contains(string, substring)
/// @param {str} string The string to check within
/// @param {str} substring The substring to search for
function string_contains(_str, _substr) 
{
    return string_pos(_substr, _str) > 0;
}