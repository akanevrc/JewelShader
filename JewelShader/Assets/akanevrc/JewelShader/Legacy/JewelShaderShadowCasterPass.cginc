#ifndef TANA_GH_JEWEL_LEGACY_SHADOW_CASTER_PASS_INCLUDED
#define TANA_GH_JEWEL_LEGACY_SHADOW_CASTER_PASS_INCLUDED

#include "UnityCG.cginc"

struct appdata
{
    float4 vertex : POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    V2F_SHADOW_CASTER;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

v2f vert (appdata v)
{
    v2f o = (v2f)0;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_TRANSFER_INSTANCE_ID(v, o);
    
    o.pos = UnityObjectToClipPos(v.vertex);
    TRANSFER_SHADOW_CASTER(o);
    return o;
}

float4 frag(v2f i) : SV_TARGET
{
    UNITY_SETUP_INSTANCE_ID(i);
    SHADOW_CASTER_FRAGMENT(i)
}

#endif // TANA_GH_JEWEL_LEGACY_SHADOW_CASTER_PASS_INCLUDED
