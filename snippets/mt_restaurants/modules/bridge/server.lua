local frameworks = {
    qbx = 'qbx_core',
    qb = 'qb-core',
    esx = 'es_extended'
}
local framework = nil

-- This is made this way because qbx_core uses qb-core provider and it'll be loaded by mistake sometimes
if GetResourceState('qbx_core') == 'started' then
    framework = 'qbx'
else
    for index, resource in pairs(frameworks) do
        if GetResourceState(resource) == 'started' then
            framework = index
            break
        end
    end
end

if not framework then
    lib.print.warn('No framework found. Please install one of the following: es_extended, qb-core, qbx_core')
    return
end

return framework and require(('modules.bridge.%s.server'):format(framework)) or {}
