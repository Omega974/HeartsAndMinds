
/* ----------------------------------------------------------------------------
Function: btc_fnc_side_civtreatment_boat

Description:
    Fill me when you edit me !

Parameters:
    _taskID - unique task ID. [String]

Returns:

Examples:
    (begin example)
        _result = [] call btc_fnc_side_civtreatment_boat;
    (end)

Author:
    Vdauphin

---------------------------------------------------------------------------- */

params [
    ["_taskID", "btc_side", [""]]
];

//// Choose a Marine location \\\\
private _useful = btc_city_all select {_x getVariable ["type", ""] isEqualTo "NameMarine" || _x getVariable ["hasbeach", false]};

if (_useful isEqualTo []) exitWith {[] spawn btc_fnc_side_create;};

private _city = selectRandom _useful;
private _pos = getPos _city;

//// Choose a random position \\\\
private _vehpos = [_pos, 0, 600, 20, 2, 60 * (pi / 180), 0] call BIS_fnc_findSafePos;
_vehpos = [_vehpos select 0 , _vehpos select 1, 0];

private _jip = [_taskID, 10, _vehpos, _city getVariable "name"] call btc_fnc_task_create;

//// Create marker \\\\
private _marker = createMarker [format ["sm_2_%1", _vehpos], _vehpos];
_marker setMarkerType "hd_flag";
[_marker, "STR_BTC_HAM_SIDE_CIVTREAT_MRK"] remoteExecCall ["btc_fnc_set_markerTextLocal", [0, -2] select isDedicated, _marker]; //Civil need help
_marker setMarkerSize [0.6, 0.6];

//// Create civ on _vehpos \\\\
private _veh_type = selectRandom btc_civ_type_boats;
private _veh = createVehicle [_veh_type, _vehpos, [], 0, "NONE"];
_veh setDir (random 360);
_veh setPos _vehpos;

private _unit_type = selectRandom btc_civ_type_units;
private _group = createGroup civilian;
_group setVariable ["no_cache", true];
private _unit = _group createUnit [_unit_type, _pos, [], 0, "NONE"];
private _index = 1 + floor (random (_veh emptyPositions "cargo"));
_unit assignAsCargoIndex [_veh, _index];
_unit moveinCargo [_veh, _index];
sleep 1;
waitUntil {sleep 5; (_taskID call BIS_fnc_taskCompleted || !(playableUnits inAreaArray [getPosWorld _unit, 5000, 5000] isEqualTo []))};
[_unit] call btc_fnc_set_damage;
_unit setVariable ["ace_medical_ai_treatmentoverat", CBA_missionTime + 10000]; //Disable AI to self healing

[_group] call btc_fnc_civ_unit_create;

waitUntil {sleep 5; (_taskID call BIS_fnc_taskCompleted || !alive _unit || {_unit call ace_medical_fnc_isInStableCondition && [_unit] call ace_common_fnc_isAwake})};

[[_marker], [_veh, _group]] call btc_fnc_delete;

if (_taskID call BIS_fnc_taskState isEqualTo "CANCELED") exitWith {};
if !(alive _unit) exitWith {
    [_taskID, "FAIL"] call BIS_fnc_taskSetState;
};

10 call btc_fnc_rep_change;

[_taskID, "SUCCEEDED"] call BIS_fnc_taskSetState;
