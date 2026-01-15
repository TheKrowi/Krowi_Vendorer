local addonName, addon = ...

KROWI_LIBMAN:NewAddon(addonName, addon, {
    SetCurrent = true,
    SetUtil = true,
    SetMetaData = true,
    InitLocalization = true,
})