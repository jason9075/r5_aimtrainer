
global function Cl_RegisterLocationARENAS


struct {

    ArenasLocSettings &selectedLocation
    array choices
    array<ArenasLocSettings> locationSettings
    var scoreRui
} arenas;


void function Cl_RegisterLocationARENAS(ArenasLocSettings locationSettings)
{
    arenas.locationSettings.append(locationSettings)
}
