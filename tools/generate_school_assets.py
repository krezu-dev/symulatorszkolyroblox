"""
generate_school_assets.py
Generowanie zaawansowanych modeli 3D i animacji dla gry 'Szkolny Detektyw' za pomocą Blender Python API (bpy).

Paczka assetów 3D:
1. wielki_dzwon (z animacją kołysania)
2. szkolny_dziennik (z animacją rotacji pocisku)
3. szkolna_lawka (klasyczna ławka z zielonym stelażem)
4. szkolne_krzeslo (klasyczne krzesełko ze sklejki)
5. szafka_szkolna (rząd szafek korytarzowych)
6. talerz_pierogi (szkolny obiad z pierogami)
7. szkolny_plecak (plecak ofiary - dowód w grze)
8. kajdanki_policja (kajdanki dla Klockowych Policjantów)
9. czapka_policyjna (czapka policyjna z orzełkiem)
10. automat_przekaski (automat z wafelkami Prince Polo i colą)
11. komputer_crt (komputer z pracowni informatycznej)
12. kaloryfer_szkolny (żeliwny kaloryfer żeberkowy)
13. stojak_chemia (stojak z probówkami z sali chemicznej)
14. bramka_boisko (bramka na szkolnym boisku)
"""

import bpy
import math
import os

OUTPUT_DIR = os.path.abspath("assets/models")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def clear_scene():
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        if block.users == 0:
            bpy.data.meshes.remove(block)
    for block in bpy.data.materials:
        if block.users == 0:
            bpy.data.materials.remove(block)
    for block in bpy.data.actions:
        if block.users == 0:
            bpy.data.actions.remove(block)

def create_material(name, color_rgba, roughness=0.4, metallic=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = color_rgba
        bsdf.inputs['Roughness'].default_value = roughness
        bsdf.inputs['Metallic'].default_value = metallic
    return mat

def export_asset(name, animated=False):
    fbx_path = os.path.join(OUTPUT_DIR, f"{name}.fbx")
    obj_path = os.path.join(OUTPUT_DIR, f"{name}.obj")

    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=False,
        bake_anim=animated,
        apply_scale_options='FBX_SCALE_ALL'
    )
    bpy.ops.wm.obj_export(filepath=obj_path)
    print(f"✅ Wyeksportowano model: {name} (FBX & OBJ)")

# ========================================================
# 1. WIELKI DZWON SZKOLNY
# ========================================================
def generate_bell():
    clear_scene()
    gold_mat = create_material("ZlotoDzwon", (0.9, 0.75, 0.15, 1.0), roughness=0.25, metallic=0.9)
    wood_mat = create_material("DrewnoBelka", (0.35, 0.2, 0.1, 1.0), roughness=0.8)
    iron_mat = create_material("ZelazoUchwyt", (0.15, 0.15, 0.15, 1.0), roughness=0.5, metallic=0.7)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.5))
    beam = bpy.context.active_object
    beam.scale = (0.5, 3.5, 0.5)
    beam.data.materials.append(wood_mat)

    for y_offset in [-1.5, 1.5]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=1.0, location=(0, y_offset, 2.0))
        pillar = bpy.context.active_object
        pillar.data.materials.append(iron_mat)

    bpy.ops.mesh.primitive_cone_add(radius1=1.4, radius2=0.5, depth=1.8, location=(0, 0, 1.2))
    bell = bpy.context.active_object
    bell.data.materials.append(gold_mat)

    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, 0, 2.0))
    crown = bpy.context.active_object
    crown.data.materials.append(gold_mat)

    bpy.ops.mesh.primitive_torus_add(major_radius=1.35, minor_radius=0.12, location=(0, 0, 0.35))
    rim = bpy.context.active_object
    rim.data.materials.append(gold_mat)

    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.3, location=(0, 0, 0.4))
    clapper = bpy.context.active_object
    clapper.data.materials.append(iron_mat)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in [bell, crown, rim, clapper]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = bell
    bpy.ops.object.join()

    bell.rotation_mode = 'XYZ'
    bell.animation_data_create()
    action = bpy.data.actions.new(name="AnimacjaDzwonienia")
    bell.animation_data.action = action

    keyframes = [(1, 0), (10, math.radians(25)), (20, math.radians(-25)), (30, math.radians(12)), (40, 0)]
    for frame, angle in keyframes:
        bell.rotation_euler.y = angle
        bell.keyframe_insert(data_path="rotation_euler", index=1, frame=frame)

    export_asset("wielki_dzwon", animated=True)

# ========================================================
# 2. SZKOLNY DZIENNIK OCEN
# ========================================================
def generate_gradebook():
    clear_scene()
    red_leather = create_material("CzerwonaSkora", (0.75, 0.08, 0.08, 1.0), roughness=0.35)
    pages_white = create_material("BialeKartki", (0.95, 0.93, 0.88, 1.0), roughness=0.9)
    gold_corners = create_material("ZloteOkucia", (0.9, 0.75, 0.15, 1.0), roughness=0.2, metallic=0.9)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    cover = bpy.context.active_object
    cover.scale = (1.4, 1.9, 0.35)
    cover.data.materials.append(red_leather)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.04, 0, 0))
    pages = bpy.context.active_object
    pages.scale = (1.28, 1.78, 0.28)
    pages.data.materials.append(pages_white)

    for x in [-0.65, 0.65]:
        for y in [-0.9, 0.9]:
            bpy.ops.mesh.primitive_cube_add(size=0.18, location=(x, y, 0))
            corner = bpy.context.active_object
            corner.data.materials.append(gold_corners)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = cover
    bpy.ops.object.join()

    cover.rotation_mode = 'XYZ'
    cover.animation_data_create()
    action = bpy.data.actions.new(name="AnimacjaRzutuDziennikiem")
    cover.animation_data.action = action
    for frame, angle in [(1, 0), (15, math.radians(180)), (30, math.radians(360))]:
        cover.rotation_euler.z = angle
        cover.keyframe_insert(data_path="rotation_euler", index=2, frame=frame)

    export_asset("szkolny_dziennik", animated=True)

# ========================================================
# 3. POLSKA ŁAWKA SZKOLNA
# ========================================================
def generate_school_desk():
    clear_scene()
    wood_top = create_material("BlatDrewniany", (0.85, 0.65, 0.4, 1.0), roughness=0.6)
    metal_green = create_material("ZielonaStal", (0.1, 0.35, 0.15, 1.0), roughness=0.4, metallic=0.6)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.6))
    desk_top = bpy.context.active_object
    desk_top.scale = (3.2, 1.8, 0.12)
    desk_top.data.materials.append(wood_top)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.3))
    shelf = bpy.context.active_object
    shelf.scale = (3.0, 1.6, 0.06)
    shelf.data.materials.append(wood_top)

    leg_coords = [(-1.45, -0.75), (-1.45, 0.75), (1.45, -0.75), (1.45, 0.75)]
    for lx, ly in leg_coords:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=1.6, location=(lx, ly, 0.8))
        leg = bpy.context.active_object
        leg.data.materials.append(metal_green)

    for side_x in [-1.45, 1.45]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(side_x, 0, 0.3))
        bar = bpy.context.active_object
        bar.scale = (0.08, 1.5, 0.08)
        bar.data.materials.append(metal_green)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = desk_top
    bpy.ops.object.join()
    export_asset("szkolna_lawka")

# ========================================================
# 4. SZKOLNE KRZESŁO
# ========================================================
def generate_school_chair():
    clear_scene()
    plywood = create_material("SklejkaKrzesełka", (0.88, 0.7, 0.45, 1.0), roughness=0.6)
    metal_green = create_material("ZielonaStal", (0.1, 0.35, 0.15, 1.0), roughness=0.4, metallic=0.6)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.95))
    seat = bpy.context.active_object
    seat.scale = (1.2, 1.2, 0.08)
    seat.data.materials.append(plywood)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.55, 1.65))
    back = bpy.context.active_object
    back.scale = (1.1, 0.08, 0.6)
    back.data.materials.append(plywood)

    leg_coords = [(-0.5, -0.5), (-0.5, 0.5), (0.5, -0.5), (0.5, 0.5)]
    for lx, ly in leg_coords:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.95, location=(lx, ly, 0.475))
        leg = bpy.context.active_object
        leg.data.materials.append(metal_green)

    for ox in [-0.45, 0.45]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.75, location=(ox, -0.55, 1.35))
        tube = bpy.context.active_object
        tube.data.materials.append(metal_green)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = seat
    bpy.ops.object.join()
    export_asset("szkolne_krzeslo")

# ========================================================
# 5. SZAFKA KORYTARZOWA
# ========================================================
def generate_lockers():
    clear_scene()
    blue_metal = create_material("NiebieskiMetal", (0.15, 0.4, 0.75, 1.0), roughness=0.35, metallic=0.6)
    dark_gray = create_material("CiemnyMetal", (0.1, 0.1, 0.1, 1.0), roughness=0.5, metallic=0.8)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.0))
    body = bpy.context.active_object
    body.scale = (3.0, 1.2, 4.0)
    body.data.materials.append(blue_metal)

    for idx, x_offset in enumerate([-1.0, 0.0, 1.0]):
        bpy.ops.mesh.primitive_cube_add(size=0.1, location=(x_offset + 0.35, 0.62, 2.0))
        handle = bpy.context.active_object
        handle.scale = (0.3, 0.5, 1.2)
        handle.data.materials.append(dark_gray)

        bpy.ops.mesh.primitive_cube_add(size=0.08, location=(x_offset, 0.62, 3.5))
        badge = bpy.context.active_object
        badge.scale = (2.0, 0.2, 1.0)
        badge.data.materials.append(dark_gray)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    export_asset("szafka_szkolna")

# ========================================================
# 6. TALERZ Z PIEROGAMI
# ========================================================
def generate_pierogi_plate():
    clear_scene()
    plate_mat = create_material("BialyTalerz", (0.95, 0.95, 0.95, 1.0), roughness=0.15)
    pierogi_mat = create_material("CiastoPierogi", (0.92, 0.82, 0.65, 1.0), roughness=0.6)
    onion_mat = create_material("OkrasaCebulka", (0.45, 0.25, 0.1, 1.0), roughness=0.7)

    bpy.ops.mesh.primitive_cylinder_add(radius=1.5, depth=0.15, location=(0, 0, 0.075))
    plate = bpy.context.active_object
    plate.data.materials.append(plate_mat)

    for i in range(5):
        angle = (i / 5.0) * math.pi * 2
        px = math.cos(angle) * 0.75
        py = math.sin(angle) * 0.75
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.4, location=(px, py, 0.25))
        p = bpy.context.active_object
        p.scale = (1.4, 0.7, 0.45)
        p.rotation_euler.z = angle + math.pi / 2
        p.data.materials.append(pierogi_mat)

    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.25, location=(0, 0, 0.3))
    onion = bpy.context.active_object
    onion.scale = (1.0, 1.0, 0.3)
    onion.data.materials.append(onion_mat)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = plate
    bpy.ops.object.join()
    export_asset("talerz_pierogi")

# ========================================================
# 7. SZKOLNY PLECAK OFIARY
# ========================================================
def generate_backpack():
    clear_scene()
    fabric_blue = create_material("MaterialPlecaka", (0.1, 0.25, 0.65, 1.0), roughness=0.7)
    pocket_red = create_material("KieszenCzerwona", (0.8, 0.15, 0.15, 1.0), roughness=0.7)
    strap_black = create_material("Paski", (0.05, 0.05, 0.05, 1.0), roughness=0.9)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.9))
    body = bpy.context.active_object
    body.scale = (1.4, 1.0, 1.8)
    body.data.materials.append(fabric_blue)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.7, depth=1.0, location=(0, 0, 1.8))
    top_round = bpy.context.active_object
    top_round.rotation_euler.x = math.pi / 2
    top_round.data.materials.append(fabric_blue)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.6, 0.7))
    pocket = bpy.context.active_object
    pocket.scale = (1.1, 0.35, 1.0)
    pocket.data.materials.append(pocket_red)

    for sx in [-0.4, 0.4]:
        bpy.ops.mesh.primitive_cube_add(size=1, location=(sx, -0.55, 0.9))
        strap = bpy.context.active_object
        strap.scale = (0.2, 0.15, 1.6)
        strap.data.materials.append(strap_black)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    export_asset("szkolny_plecak")

# ========================================================
# 8. KAJDANKI POLICYJNE
# ========================================================
def generate_handcuffs():
    clear_scene()
    steel = create_material("KajdankiStal", (0.8, 0.8, 0.85, 1.0), roughness=0.2, metallic=0.95)

    for cx in [-0.5, 0.5]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.35, minor_radius=0.07, location=(cx, 0, 0))
        cuff = bpy.context.active_object
        cuff.data.materials.append(steel)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.4, location=(0, 0, 0))
    chain = bpy.context.active_object
    chain.rotation_euler.y = math.pi / 2
    chain.data.materials.append(steel)

    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.join()
    export_asset("kajdanki_policja")

# ========================================================
# 9. CZAPKA POLICYJNA
# ========================================================
def generate_police_cap():
    clear_scene()
    cap_blue = create_material("GranatMundur", (0.05, 0.1, 0.35, 1.0), roughness=0.6)
    visor_black = create_material("CzarneTworzywo", (0.02, 0.02, 0.02, 1.0), roughness=0.1)
    badge_gold = create_material("ZlotyOrzelek", (0.9, 0.8, 0.2, 1.0), roughness=0.2, metallic=0.9)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=0.5, location=(0, 0, 0.25))
    crown = bpy.context.active_object
    crown.scale = (1.1, 1.25, 0.8)
    crown.data.materials.append(cap_blue)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.75, depth=0.06, location=(0, 0.7, 0.05))
    visor = bpy.context.active_object
    visor.scale = (1.1, 0.8, 1.0)
    visor.rotation_euler.x = math.radians(-15)
    visor.data.materials.append(visor_black)

    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.05, location=(0, 0.85, 0.3))
    badge = bpy.context.active_object
    badge.rotation_euler.x = math.pi / 2
    badge.data.materials.append(badge_gold)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = crown
    bpy.ops.object.join()
    export_asset("czapka_policyjna")

# ========================================================
# 10. SZKOLNY AUTOMAT Z PRZEKĄSKAMI (VENDING MACHINE)
# ========================================================
def generate_vending_machine():
    clear_scene()
    case_mat = create_material("ObudowaAutomatu", (0.1, 0.12, 0.18, 1.0), roughness=0.35, metallic=0.8)
    glass_mat = create_material("SzybaAutomatu", (0.8, 0.9, 0.95, 0.3), roughness=0.1)
    snack_red = create_material("WafelkiPrincePolo", (0.8, 0.1, 0.1, 1.0), roughness=0.6)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.5))
    case = bpy.context.active_object
    case.scale = (2.2, 1.8, 5.0)
    case.data.materials.append(case_mat)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.75, 3.0))
    glass = bpy.context.active_object
    glass.scale = (1.8, 0.4, 3.2)
    glass.data.materials.append(glass_mat)

    for z in [2.0, 3.0, 4.0]:
        for x in [-0.5, 0.0, 0.5]:
            bpy.ops.mesh.primitive_cube_add(size=0.3, location=(x, 0.5, z))
            snack = bpy.context.active_object
            snack.scale = (1.2, 0.6, 0.5)
            snack.data.materials.append(snack_red)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = case
    bpy.ops.object.join()
    export_asset("automat_przekaski")

# ========================================================
# 11. STARY KOMPUTER CRT (PRACOWNIA INFORMATYCZNA)
# ========================================================
def generate_crt_computer():
    clear_scene()
    beige_plastic = create_material("BialyZoltyPlastik", (0.85, 0.83, 0.75, 1.0), roughness=0.5)
    screen_glass = create_material("EkranCRT", (0.15, 0.2, 0.25, 1.0), roughness=0.1)
    pc_case = create_material("ObudowaPC", (0.8, 0.78, 0.7, 1.0), roughness=0.6)

    # Monitor kineskopowy
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.2))
    monitor = bpy.context.active_object
    monitor.scale = (1.4, 1.5, 1.2)
    monitor.data.materials.append(beige_plastic)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.65, 1.2))
    screen = bpy.context.active_object
    screen.scale = (1.1, 0.25, 0.9)
    screen.data.materials.append(screen_glass)

    # Klawiatura
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 1.4, 0.1))
    keyboard = bpy.context.active_object
    keyboard.scale = (1.5, 0.6, 0.12)
    keyboard.data.materials.append(beige_plastic)

    # Jednostka centralna (desktop)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.3))
    pc = bpy.context.active_object
    pc.scale = (1.6, 1.8, 0.5)
    pc.data.materials.append(pc_case)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = monitor
    bpy.ops.object.join()
    export_asset("komputer_crt")

# ========================================================
# 12. ŻELIWNY KALORYFER SZKOLNY
# ========================================================
def generate_radiator():
    clear_scene()
    cast_iron = create_material("ZeliwoKaloryfer", (0.85, 0.85, 0.85, 1.0), roughness=0.45, metallic=0.5)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.0))
    main_rib = bpy.context.active_object
    main_rib.scale = (0.2, 0.5, 2.0)
    main_rib.data.materials.append(cast_iron)

    for i in range(1, 10):
        x = i * 0.35
        bpy.ops.mesh.primitive_cube_add(size=1, location=(x, 0, 1.0))
        rib = bpy.context.active_object
        rib.scale = (0.2, 0.5, 2.0)
        rib.data.materials.append(cast_iron)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = main_rib
    bpy.ops.object.join()
    export_asset("kaloryfer_szkolny")

# ========================================================
# 13. STOJAK Z PROBÓWKAMI (CHEMIA)
# ========================================================
def generate_chemistry_stand():
    clear_scene()
    wood_mat = create_material("DrewnoStojak", (0.4, 0.25, 0.15, 1.0), roughness=0.7)
    glass_mat = create_material("SzkloProbowki", (0.8, 0.9, 1.0, 0.3), roughness=0.1)
    liquid_colored = create_material("PlynChemikalia", (0.1, 0.8, 0.3, 1.0), roughness=0.2)

    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
    stand = bpy.context.active_object
    stand.scale = (2.4, 0.6, 1.0)
    stand.data.materials.append(wood_mat)

    for i in range(4):
        x = -0.9 + (i * 0.6)
        bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=1.2, location=(x, 0, 0.9))
        tube = bpy.context.active_object
        tube.data.materials.append(glass_mat)

        bpy.ops.mesh.primitive_cylinder_add(radius=0.1, depth=0.6, location=(x, 0, 0.6))
        liq = bpy.context.active_object
        liq.data.materials.append(liquid_colored)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = stand
    bpy.ops.object.join()
    export_asset("stojak_chemia")

# ========================================================
# 14. BRAMKA NA BOISKO ORLIK
# ========================================================
def generate_goal_post():
    clear_scene()
    white_steel = create_material("BialySlup", (0.95, 0.95, 0.95, 1.0), roughness=0.3, metallic=0.7)

    # Poprzeczka
    bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=5.0, location=(0, 0, 2.2))
    crossbar = bpy.context.active_object
    crossbar.rotation_euler.y = math.pi / 2
    crossbar.data.materials.append(white_steel)

    # 2 słupki
    for x in [-2.5, 2.5]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=2.2, location=(x, 0, 1.1))
        post = bpy.context.active_object
        post.data.materials.append(white_steel)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = crossbar
    bpy.ops.object.join()
    export_asset("bramka_boisko")

def main():
    print("🚀 Rozpoczynam generowanie powiększonego pakietu 3D dla wielkiej szkoły...")
    generate_bell()
    generate_gradebook()
    generate_school_desk()
    generate_school_chair()
    generate_lockers()
    generate_pierogi_plate()
    generate_backpack()
    generate_handcuffs()
    generate_police_cap()
    generate_vending_machine()
    generate_crt_computer()
    generate_radiator()
    generate_chemistry_stand()
    generate_goal_post()
    print("✨ Kompletny zestaw 14 modeli 3D został wyeksportowany do assets/models/!")

if __name__ == "__main__":
    main()
