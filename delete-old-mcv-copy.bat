@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM ==========================================================================
REM 42Bros - delete our old copy of the Military Conflict: Vietnam code
REM
REM Put this file in the addon's folder (addons\1942_darkrp, next to the lua
REM folder) and double-click it. It deletes exactly 225 files from the list
REM below and nothing else: mcv_mg42b.lua and every rp1942_ file stay.
REM ==========================================================================
cd /d "%~dp0"

if not exist "lua\autorun\" goto wrongplace
if not exist "lua\darkrp_modules\" goto wrongplace

echo This deletes the old copy of the Military Conflict: Vietnam code from:
echo    %CD%
echo.
echo Kept: lua\weapons\mcv_mg42b.lua and everything named rp1942_...
echo.
set /p ok=Type YES and press Enter to delete: 
if /i not "!ok!"=="YES" (
    echo Nothing was deleted.
    goto done
)

set /a gone=0

REM Whole folders (only the pack's code is in them)
if exist "lua\mcv\" ( rmdir /s /q "lua\mcv" & echo Deleted folder lua\mcv & set /a gone+=1 )
if exist "lua\weapons\mcv_base\" ( rmdir /s /q "lua\weapons\mcv_base" & echo Deleted folder lua\weapons\mcv_base & set /a gone+=1 )
if exist "lua\weapons\mcv_base_core\" ( rmdir /s /q "lua\weapons\mcv_base_core" & echo Deleted folder lua\weapons\mcv_base_core & set /a gone+=1 )
if exist "lua\weapons\mcv_binoculars\" ( rmdir /s /q "lua\weapons\mcv_binoculars" & echo Deleted folder lua\weapons\mcv_binoculars & set /a gone+=1 )
if exist "lua\weapons\mcv_equipment_box\" ( rmdir /s /q "lua\weapons\mcv_equipment_box" & echo Deleted folder lua\weapons\mcv_equipment_box & set /a gone+=1 )
if exist "lua\weapons\mcv_flamethrower\" ( rmdir /s /q "lua\weapons\mcv_flamethrower" & echo Deleted folder lua\weapons\mcv_flamethrower & set /a gone+=1 )
if exist "lua\weapons\mcv_melee\" ( rmdir /s /q "lua\weapons\mcv_melee" & echo Deleted folder lua\weapons\mcv_melee & set /a gone+=1 )
if exist "lua\weapons\mcv_placeable\" ( rmdir /s /q "lua\weapons\mcv_placeable" & echo Deleted folder lua\weapons\mcv_placeable & set /a gone+=1 )
if exist "lua\weapons\mcv_throwable\" ( rmdir /s /q "lua\weapons\mcv_throwable" & echo Deleted folder lua\weapons\mcv_throwable & set /a gone+=1 )
if exist "lua\weapons\mcv_underbarrel_flame\" ( rmdir /s /q "lua\weapons\mcv_underbarrel_flame" & echo Deleted folder lua\weapons\mcv_underbarrel_flame & set /a gone+=1 )

REM Single files
if exist "lua\effects\mcv_impact.lua" ( del /f /q "lua\effects\mcv_impact.lua" & set /a gone+=1 )
if exist "lua\effects\mcv_muzzleeffect.lua" ( del /f /q "lua\effects\mcv_muzzleeffect.lua" & set /a gone+=1 )
if exist "lua\effects\mcv_shelleffect.lua" ( del /f /q "lua\effects\mcv_shelleffect.lua" & set /a gone+=1 )
if exist "lua\effects\mcv_tracer.lua" ( del /f /q "lua\effects\mcv_tracer.lua" & set /a gone+=1 )
if exist "lua\autorun\sh_mcv_harness.lua" ( del /f /q "lua\autorun\sh_mcv_harness.lua" & set /a gone+=1 )
if exist "lua\autorun\sh_mcv_load.lua" ( del /f /q "lua\autorun\sh_mcv_load.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_firepool.lua" ( del /f /q "lua\entities\mcv_firepool.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_grenade_base.lua" ( del /f /q "lua\entities\mcv_grenade_base.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_grenade_frag.lua" ( del /f /q "lua\entities\mcv_grenade_frag.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_grenade_gas.lua" ( del /f /q "lua\entities\mcv_grenade_gas.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_grenade_molotov.lua" ( del /f /q "lua\entities\mcv_grenade_molotov.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_grenade_smoke.lua" ( del /f /q "lua\entities\mcv_grenade_smoke.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_grenade_wp.lua" ( del /f /q "lua\entities\mcv_grenade_wp.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_mine_stake.lua" ( del /f /q "lua\entities\mcv_mine_stake.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_placed_c4.lua" ( del /f /q "lua\entities\mcv_placed_c4.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_placed_dynamite.lua" ( del /f /q "lua\entities\mcv_placed_dynamite.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_placed_mine.lua" ( del /f /q "lua\entities\mcv_placed_mine.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_40mm.lua" ( del /f /q "lua\entities\mcv_proj_40mm.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_base.lua" ( del /f /q "lua\entities\mcv_proj_base.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_bazooka.lua" ( del /f /q "lua\entities\mcv_proj_bazooka.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_bolt.lua" ( del /f /q "lua\entities\mcv_proj_bolt.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_flare.lua" ( del /f /q "lua\entities\mcv_proj_flare.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_flare_vc.lua" ( del /f /q "lua\entities\mcv_proj_flare_vc.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_kolos.lua" ( del /f /q "lua\entities\mcv_proj_kolos.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_lunge_mine.lua" ( del /f /q "lua\entities\mcv_proj_lunge_mine.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_m202.lua" ( del /f /q "lua\entities\mcv_proj_m202.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_panzerschreck.lua" ( del /f /q "lua\entities\mcv_proj_panzerschreck.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_riflegrenade.lua" ( del /f /q "lua\entities\mcv_proj_riflegrenade.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_riflegrenade_ger.lua" ( del /f /q "lua\entities\mcv_proj_riflegrenade_ger.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_riflegrenade_vc.lua" ( del /f /q "lua\entities\mcv_proj_riflegrenade_vc.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_rpg.lua" ( del /f /q "lua\entities\mcv_proj_rpg.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_proj_rpg2.lua" ( del /f /q "lua\entities\mcv_proj_rpg2.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_supply_box.lua" ( del /f /q "lua\entities\mcv_supply_box.lua" & set /a gone+=1 )
if exist "lua\entities\mcv_thrown_melee.lua" ( del /f /q "lua\entities\mcv_thrown_melee.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ammobox_us.lua" ( del /f /q "lua\weapons\mcv_ammobox_us.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ammobox_vc.lua" ( del /f /q "lua\weapons\mcv_ammobox_vc.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_anm8.lua" ( del /f /q "lua\weapons\mcv_anm8.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_avt40.lua" ( del /f /q "lua\weapons\mcv_avt40.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_babybrowning.lua" ( del /f /q "lua\weapons\mcv_babybrowning.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_bazooka.lua" ( del /f /q "lua\weapons\mcv_bazooka.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_binoculars_us.lua" ( del /f /q "lua\weapons\mcv_binoculars_us.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_binoculars_vc.lua" ( del /f /q "lua\weapons\mcv_binoculars_vc.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_blackhawk.lua" ( del /f /q "lua\weapons\mcv_blackhawk.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_bren.lua" ( del /f /q "lua\weapons\mcv_bren.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_browning_auto.lua" ( del /f /q "lua\weapons\mcv_browning_auto.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_c96.lua" ( del /f /q "lua\weapons\mcv_c96.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_c96_stock.lua" ( del /f /q "lua\weapons\mcv_c96_stock.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_crossbow.lua" ( del /f /q "lua\weapons\mcv_crossbow.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_crowbar.lua" ( del /f /q "lua\weapons\mcv_crowbar.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_css.lua" ( del /f /q "lua\weapons\mcv_css.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_dp28.lua" ( del /f /q "lua\weapons\mcv_dp28.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_dynamite.lua" ( del /f /q "lua\weapons\mcv_dynamite.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_fists.lua" ( del /f /q "lua\weapons\mcv_fists.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_fm24.lua" ( del /f /q "lua\weapons\mcv_fm24.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_fusil_robust.lua" ( del /f /q "lua\weapons\mcv_fusil_robust.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_fusil_robust_short.lua" ( del /f /q "lua\weapons\mcv_fusil_robust_short.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_g43.lua" ( del /f /q "lua\weapons\mcv_g43.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_hipower.lua" ( del /f /q "lua\weapons\mcv_hipower.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_kar98.lua" ( del /f /q "lua\weapons\mcv_kar98.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_kar98_prewar.lua" ( del /f /q "lua\weapons\mcv_kar98_prewar.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_kar98_prewar_s.lua" ( del /f /q "lua\weapons\mcv_kar98_prewar_s.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_kar98_prewar_zf41.lua" ( del /f /q "lua\weapons\mcv_kar98_prewar_zf41.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_kar98_s.lua" ( del /f /q "lua\weapons\mcv_kar98_s.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_kar98_zf41.lua" ( del /f /q "lua\weapons\mcv_kar98_zf41.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_katana.lua" ( del /f /q "lua\weapons\mcv_katana.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_lebel.lua" ( del /f /q "lua\weapons\mcv_lebel.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_luger.lua" ( del /f /q "lua\weapons\mcv_luger.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_lunge_mine.lua" ( del /f /q "lua\weapons\mcv_lunge_mine.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m16mine.lua" ( del /f /q "lua\weapons\mcv_m16mine.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m18.lua" ( del /f /q "lua\weapons\mcv_m18.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1895.lua" ( del /f /q "lua\weapons\mcv_m1895.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1897.lua" ( del /f /q "lua\weapons\mcv_m1897.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1905_bayonet.lua" ( del /f /q "lua\weapons\mcv_m1905_bayonet.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1911a1.lua" ( del /f /q "lua\weapons\mcv_m1911a1.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1917.lua" ( del /f /q "lua\weapons\mcv_m1917.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1918.lua" ( del /f /q "lua\weapons\mcv_m1918.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1918_bar.lua" ( del /f /q "lua\weapons\mcv_m1918_bar.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1919.lua" ( del /f /q "lua\weapons\mcv_m1919.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1942_machete.lua" ( del /f /q "lua\weapons\mcv_m1942_machete.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1_carbine.lua" ( del /f /q "lua\weapons\mcv_m1_carbine.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1c.lua" ( del /f /q "lua\weapons\mcv_m1c.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1c_sog.lua" ( del /f /q "lua\weapons\mcv_m1c_sog.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1d.lua" ( del /f /q "lua\weapons\mcv_m1d.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m1g.lua" ( del /f /q "lua\weapons\mcv_m1g.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m2c.lua" ( del /f /q "lua\weapons\mcv_m2c.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m2c_sog.lua" ( del /f /q "lua\weapons\mcv_m2c_sog.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m37.lua" ( del /f /q "lua\weapons\mcv_m37.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m38.lua" ( del /f /q "lua\weapons\mcv_m38.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m38_s.lua" ( del /f /q "lua\weapons\mcv_m38_s.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m3a1.lua" ( del /f /q "lua\weapons\mcv_m3a1.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m3a1_sog.lua" ( del /f /q "lua\weapons\mcv_m3a1_sog.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m45.lua" ( del /f /q "lua\weapons\mcv_m45.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m50r.lua" ( del /f /q "lua\weapons\mcv_m50r.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m55r.lua" ( del /f /q "lua\weapons\mcv_m55r.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m8.lua" ( del /f /q "lua\weapons\mcv_m8.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m91.lua" ( del /f /q "lua\weapons\mcv_m91.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_m9a1.lua" ( del /f /q "lua\weapons\mcv_m9a1.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mas36.lua" ( del /f /q "lua\weapons\mcv_mas36.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mas36_cr39.lua" ( del /f /q "lua\weapons\mcv_mas36_cr39.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mas38.lua" ( del /f /q "lua\weapons\mcv_mas38.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_medicbox_us.lua" ( del /f /q "lua\weapons\mcv_medicbox_us.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_medicbox_vc.lua" ( del /f /q "lua\weapons\mcv_medicbox_vc.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mg43.lua" ( del /f /q "lua\weapons\mcv_mg43.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mg43b.lua" ( del /f /q "lua\weapons\mcv_mg43b.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mg43d.lua" ( del /f /q "lua\weapons\mcv_mg43d.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mk2.lua" ( del /f /q "lua\weapons\mcv_mk2.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mk3a2.lua" ( del /f /q "lua\weapons\mcv_mk3a2.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mle1935.lua" ( del /f /q "lua\weapons\mcv_mle1935.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_molotov.lua" ( del /f /q "lua\weapons\mcv_molotov.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_mp40.lua" ( del /f /q "lua\weapons\mcv_mp40.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_owen.lua" ( del /f /q "lua\weapons\mcv_owen.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_p38.lua" ( del /f /q "lua\weapons\mcv_p38.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_panzerschreck.lua" ( del /f /q "lua\weapons\mcv_panzerschreck.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ppk.lua" ( del /f /q "lua\weapons\mcv_ppk.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_pps43.lua" ( del /f /q "lua\weapons\mcv_pps43.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ppsh41.lua" ( del /f /q "lua\weapons\mcv_ppsh41.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ppsh41_drum.lua" ( del /f /q "lua\weapons\mcv_ppsh41_drum.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ppsh41dd.lua" ( del /f /q "lua\weapons\mcv_ppsh41dd.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ptrd.lua" ( del /f /q "lua\weapons\mcv_ptrd.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ptrd_sniper.lua" ( del /f /q "lua\weapons\mcv_ptrd_sniper.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_rp46.lua" ( del /f /q "lua\weapons\mcv_rp46.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_rpd.lua" ( del /f /q "lua\weapons\mcv_rpd.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_rpdb.lua" ( del /f /q "lua\weapons\mcv_rpdb.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_ruby.lua" ( del /f /q "lua\weapons\mcv_ruby.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_shovel_ger.lua" ( del /f /q "lua\weapons\mcv_shovel_ger.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_shovel_us.lua" ( del /f /q "lua\weapons\mcv_shovel_us.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_shovel_vc.lua" ( del /f /q "lua\weapons\mcv_shovel_vc.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_sickle.lua" ( del /f /q "lua\weapons\mcv_sickle.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_springfield.lua" ( del /f /q "lua\weapons\mcv_springfield.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_springfield_s.lua" ( del /f /q "lua\weapons\mcv_springfield_s.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_sten.lua" ( del /f /q "lua\weapons\mcv_sten.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_sten_sog.lua" ( del /f /q "lua\weapons\mcv_sten_sog.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_stg44.lua" ( del /f /q "lua\weapons\mcv_stg44.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_stg44_s.lua" ( del /f /q "lua\weapons\mcv_stg44_s.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_stg44_zf41.lua" ( del /f /q "lua\weapons\mcv_stg44_zf41.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_stielhand_explosive.lua" ( del /f /q "lua\weapons\mcv_stielhand_explosive.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_stielhand_smoke.lua" ( del /f /q "lua\weapons\mcv_stielhand_smoke.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_svt40.lua" ( del /f /q "lua\weapons\mcv_svt40.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_svt40_s.lua" ( del /f /q "lua\weapons\mcv_svt40_s.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_swm10.lua" ( del /f /q "lua\weapons\mcv_swm10.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_thompson.lua" ( del /f /q "lua\weapons\mcv_thompson.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_thompson_m1928.lua" ( del /f /q "lua\weapons\mcv_thompson_m1928.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_thompson_sog.lua" ( del /f /q "lua\weapons\mcv_thompson_sog.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_tt33.lua" ( del /f /q "lua\weapons\mcv_tt33.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_type14.lua" ( del /f /q "lua\weapons\mcv_type14.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_type30_bayonet.lua" ( del /f /q "lua\weapons\mcv_type30_bayonet.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_type97.lua" ( del /f /q "lua\weapons\mcv_type97.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vccarbine.lua" ( del /f /q "lua\weapons\mcv_vccarbine.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vcgrenade.lua" ( del /f /q "lua\weapons\mcv_vcgrenade.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vcpistol.lua" ( del /f /q "lua\weapons\mcv_vcpistol.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vcpistol2.lua" ( del /f /q "lua\weapons\mcv_vcpistol2.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vcshotgun.lua" ( del /f /q "lua\weapons\mcv_vcshotgun.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vcsmg.lua" ( del /f /q "lua\weapons\mcv_vcsmg.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_vz24.lua" ( del /f /q "lua\weapons\mcv_vz24.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_welrod.lua" ( del /f /q "lua\weapons\mcv_welrod.lua" & set /a gone+=1 )
if exist "lua\weapons\mcv_wrench.lua" ( del /f /q "lua\weapons\mcv_wrench.lua" & set /a gone+=1 )

echo.
echo Done: deleted !gone! folder(s) and file(s).
if exist "lua\weapons\mcv_mg42b.lua" ( echo Kept lua\weapons\mcv_mg42b.lua. ) else ( echo Note: lua\weapons\mcv_mg42b.lua is not here - copy it in from the zip. )
if exist "lua\autorun\rp1942_mcv_patches.lua" ( echo lua\autorun\rp1942_mcv_patches.lua is in place. ) else ( echo Next: copy in lua\autorun\rp1942_mcv_patches.lua from the zip. )
echo Then restart the server.
goto done

:wrongplace
echo This isn't the addon's folder.
echo Put this file in addons\1942_darkrp (the folder that has the lua folder in it) and run it again.
echo Nothing was deleted.

:done
echo.
pause
