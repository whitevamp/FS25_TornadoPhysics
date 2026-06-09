-- TORNADO PHYSICS IGNORE LIST V4.0
-- Bans visual roots (_vis), pallets, heaps, and internal game logic.

TornadoMod_IgnoreList = {
    -- CRITICAL FIXES (Prevents full invisibility)
    "_vis", "_visual", "visNode", 
    "main_component", "root", "parent",
    
    -- GAMEPLAY OBJECTS (Do not hide these, just move them)
    "pallet", "box", "crate", "bale", "stack", "heap", "pile",
    
    -- LOGIC & TRIGGERS (The "Manure Heap" fix)
    "indoorArea", "indoorAreas", "inside", "outdoor", -- Rain blockers
    "spline", "trigger", "marker", "helper", "barrier", "boundary", "mask", "plane",
    "occluder", "shadow", "navmesh", "camera", "target", "tip", "start", "end", 
    "load", "unload", "spawn", "hotspot", "map", "icon", "ref", "index", 
    "attacher", "connector", "link", "pivot", "center", "offset", "joint",
    
    -- AUDIO & FX
    ".wav", ".ogg", "sound", "audio", "effect", "particle", "smoke", "dust", 
    "emitter", "exhaust", "sfx", "foley", 

    -- PHYSICS BODIES
    "_col", "_coll", "collision", "rigidBody", "compound", "physics", 

    -- INFRASTRUCTURE
    "road", "street", "path", "walkway", "highway", "asphalt", "concrete", 
    "gravel", "sidewalk", "traffic", "border",
    "terrain", "ground", "deco", "foliage", "rock", "stone", "mountain", 
    "river", "water", "lake", "sky", "cloud"
}