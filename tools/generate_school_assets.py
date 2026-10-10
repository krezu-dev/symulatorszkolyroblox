"""
generate_school_assets.py
Generowanie modeli 3D i animacji dla gry 'Szkolny Detektyw' za pomocą Blender Python API (bpy).

Generuje modele w formatach FBX i OBJ gotowe do importu do Roblox Studio:
1. wielki_dzwon (z animacją kołysania)
2. szkolny_dziennik (z animacją rotacji pocisku)
3. szkolna_lawka (klasyczna ławka z zielonym stelażem)
4. szkolne_krzeslo (klasyczne krzesełko ze sklejki)
5. szafka_szkolna (rząd szafek korytarzowych)
6. talerz_pierogi (szkolny obiad z pierogami)
7. szkolny_plecak (plecak ofiary - dowód w grze)
8. kajdanki_policja (kajdanki dla Klockowych Policjantów)
9. czapka_policyjna (czapka policyjna)
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

    # Export FBX
    bpy.ops.export_scene.fbx(
        filepath=fbx_path,
        use_selection=False,
        bake_anim=animated,
        apply_scale_options='FBX_SCALE_ALL'
    )
    # Export OBJ
    bpy.ops.wm.obj_export(filepath=obj_path)
    print(f"✅ Wyeksportowano model: {name} (FBX & OBJ)")

# ========================================================
# 1. WIELKI DZWON SZKOLNY (z animacją kołysania)
# ========================================================
def generate_bell():
    clear_scene()
    gold_mat = create_material("ZlotoDzwon", (0.9, 0.75, 0.15, 1.0), roughness=0.25, metallic=0.9)
    wood_mat = create_material("DrewnoBelka", (0.35, 0.2, 0.1, 1.0), roughness=0.8)
    iron_mat = create_material("ZelazoUchwyt", (0.15, 0.15, 0.15, 1.0), roughness=0.5, metallic=0.7)

    # Drewniana belka nośna
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.5))
    beam = bpy.context.active_object
    beam.name = "BelkaNosna"
    beam.scale = (0.5, 3.5, 0.5)
    beam.data.materials.append(wood_mat)

    # Żelazne podpory
    for y_offset in [-1.5, 1.5]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.15, depth=1.0, location=(0, y_offset, 2.0))
        pillar = bpy.context.active_object
        pillar.data.materials.append(iron_mat)

    # Główna czasza dzwonu
    bpy.ops.mesh.primitive_cone_add(radius1=1.4, radius2=0.5, depth=1.8, location=(0, 0, 1.2))
    bell = bpy.context.active_object
    bell.name = "CzaszaDzwonu"
    bell.data.materials.append(gold_mat)

    # Korona / zaokrąglenie góry
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.55, location=(0, 0, 2.0))
    crown = bpy.context.active_object
    crown.data.materials.append(gold_mat)

    # Brzeg dolny dzwonu (pierścień)
    bpy.ops.mesh.primitive_torus_add(major_radius=1.35, minor_radius=0.12, location=(0, 0, 0.35))
    rim = bpy.context.active_object
    rim.data.materials.append(gold_mat)

    # Serce dzwonu (clapper)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.3, location=(0, 0, 0.4))
    clapper = bpy.context.active_object
    clapper.data.materials.append(iron_mat)

    # Połącz części dzwonu do animacji kołysania
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [bell, crown, rim, clapper]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = bell
    bpy.ops.object.join()

    # Utwórz animację kołysania dzwonu (40 klatek)
    bell.rotation_mode = 'XYZ'
    bell.animation_data_create()
    action = bpy.data.actions.new(name="AnimacjaDzwonienia")
    bell.animation_data.action = action

    keyframes = [
        (1, 0),
        (10, math.radians(25)),
        (20, math.radians(-25)),
        (30, math.radians(12)),
        (40, 0)
    ]
    for frame, angle in keyframes:
        bell.rotation_euler.y = angle
        bell.keyframe_insert(data_path="rotation_euler", index=1, frame=frame)

    export_asset("wielki_dzwon", animated=True)

# ========================================================
# 2. SZKOLNY DZIENNIK OCEN (z rotacją rzutu)
# ========================================================
def generate_gradebook():
    clear_scene()
    red_leather = create_material("CzerwonaSkora", (0.75, 0.08, 0.08, 1.0), roughness=0.35)
    pages_white = create_material("BialeKartki", (0.95, 0.93, 0.88, 1.0), roughness=0.9)
    gold_corners = create_material("ZloteOkucia", (0.9, 0.75, 0.15, 1.0), roughness=0.2, metallic=0.9)

    # Okładka główna
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0))
    cover = bpy.context.active_object
    cover.name = "DziennikOcen"
    cover.scale = (1.4, 1.9, 0.35)
    cover.data.materials.append(red_leather)

    # Blok kartek w środku
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.04, 0, 0))
    pages = bpy.context.active_object
    pages.scale = (1.28, 1.78, 0.28)
    pages.data.materials.append(pages_white)

    # Złote narożniki (okucia dziennika)
    for x in [-0.65, 0.65]:
        for y in [-0.9, 0.9]:
            bpy.ops.mesh.primitive_cube_add(size=0.18, location=(x, y, 0))
            corner = bpy.context.active_object
            corner.data.materials.append(gold_corners)

    # Połącz do pojedynczego MeshParta
    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = cover
    bpy.ops.object.join()

    # Animacja wirowania pocisku w locie (30 klatek)
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

    # Blat ławki
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.6))
    desk_top = bpy.context.active_object
    desk_top.name = "BlatLawki"
    desk_top.scale = (3.2, 1.8, 0.12)
    desk_top.data.materials.append(wood_top)

    # Półka pod blatem na podręczniki
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.3))
    shelf = bpy.context.active_object
    shelf.scale = (3.0, 1.6, 0.06)
    shelf.data.materials.append(wood_top)

    # 4 metalowe nogi (zielone rurki)
    leg_coords = [(-1.45, -0.75), (-1.45, 0.75), (1.45, -0.75), (1.45, 0.75)]
    for lx, ly in leg_coords:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.06, depth=1.6, location=(lx, ly, 0.8))
        leg = bpy.context.active_object
        leg.data.materials.append(metal_green)

    # Dolna belka usztywniająca
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

    # Siedzisko ze sklejki
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.95))
    seat = bpy.context.active_object
    seat.name = "Siedzisko"
    seat.scale = (1.2, 1.2, 0.08)
    seat.data.materials.append(plywood)

    # Oparcie ze sklejki
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, -0.55, 1.65))
    back = bpy.context.active_object
    back.scale = (1.1, 0.08, 0.6)
    back.data.materials.append(plywood)

    # 4 nogi krzesła
    leg_coords = [(-0.5, -0.5), (-0.5, 0.5), (0.5, -0.5), (0.5, 0.5)]
    for lx, ly in leg_coords:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.04, depth=0.95, location=(lx, ly, 0.475))
        leg = bpy.context.active_object
        leg.data.materials.append(metal_green)

    # Rurki oparcia
    for ox in [-0.45, 0.45]:
        bpy.ops.mesh.primitive_cylinder_add(radius=0.035, depth=0.75, location=(ox, -0.55, 1.35))
        tube = bpy.context.active_object
        tube.data.materials.append(metal_green)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = seat
    bpy.ops.object.join()
    export_asset("szkolne_krzeslo")

# ========================================================
# 5. SZAFKA KORYTARZOWA (LOCKERS)
# ========================================================
def generate_lockers():
    clear_scene()
    blue_metal = create_material("NiebieskiMetal", (0.15, 0.4, 0.75, 1.0), roughness=0.35, metallic=0.6)
    dark_gray = create_material("CiemnyMetal", (0.1, 0.1, 0.1, 1.0), roughness=0.5, metallic=0.8)

    # Obudowa potrójnej szafki
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 2.0))
    body = bpy.context.active_object
    body.name = "SzafkaKorytarz"
    body.scale = (3.0, 1.2, 4.0)
    body.data.materials.append(blue_metal)

    # 3 drzwi z uchwytami i szczelinami wentylacyjnymi
    for idx, x_offset in enumerate([-1.0, 0.0, 1.0]):
        # Klamka / uchwyt
        bpy.ops.mesh.primitive_cube_add(size=0.1, location=(x_offset + 0.35, 0.62, 2.0))
        handle = bpy.context.active_object
        handle.scale = (0.3, 0.5, 1.2)
        handle.data.materials.append(dark_gray)

        # Tabliczka z numerem szafki
        bpy.ops.mesh.primitive_cube_add(size=0.08, location=(x_offset, 0.62, 3.5))
        badge = bpy.context.active_object
        badge.scale = (2.0, 0.2, 1.0)
        badge.data.materials.append(dark_gray)

        # Szczeliny wentylacyjne (3 kratki)
        for v in [3.1, 3.2, 3.3]:
            bpy.ops.mesh.primitive_cube_add(size=0.05, location=(x_offset, 0.62, v))
            vent = bpy.context.active_object
            vent.scale = (3.5, 0.2, 0.3)
            vent.data.materials.append(dark_gray)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    export_asset("szafka_szkolna")

# ========================================================
# 6. TALERZ Z PIEROGAMI (STOŁÓWKA)
# ========================================================
def generate_pierogi_plate():
    clear_scene()
    plate_mat = create_material("BialyTalerz", (0.95, 0.95, 0.95, 1.0), roughness=0.15)
    pierogi_mat = create_material("CiastoPierogi", (0.92, 0.82, 0.65, 1.0), roughness=0.6)
    onion_mat = create_material("OkrasaCebulka", (0.45, 0.25, 0.1, 1.0), roughness=0.7)

    # Talerz
    bpy.ops.mesh.primitive_cylinder_add(radius=1.5, depth=0.15, location=(0, 0, 0.075))
    plate = bpy.context.active_object
    plate.name = "TalerzPierogow"
    plate.data.materials.append(plate_mat)

    # 5 pierogów ułożonych w okręgu
    for i in range(5):
        angle = (i / 5.0) * math.pi * 2
        px = math.cos(angle) * 0.75
        py = math.sin(angle) * 0.75

        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.4, location=(px, py, 0.25))
        p = bpy.context.active_object
        p.scale = (1.4, 0.7, 0.45)
        p.rotation_euler.z = angle + math.pi / 2
        p.data.materials.append(pierogi_mat)

    # Okrasa / skwarki na środku
    bpy.ops.mesh.primitive_uv_sphere_add(radius=0.25, location=(0, 0, 0.3))
    onion = bpy.context.active_object
    onion.scale = (1.0, 1.0, 0.3)
    onion.data.materials.append(onion_mat)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = plate
    bpy.ops.object.join()
    export_asset("talerz_pierogi")

# ========================================================
# 7. SZKOLNY PLECAK OFIARY (EVIDENCE)
# ========================================================
def generate_backpack():
    clear_scene()
    fabric_blue = create_material("MaterialPlecaka", (0.1, 0.25, 0.65, 1.0), roughness=0.7)
    pocket_red = create_material("KieszenCzerwona", (0.8, 0.15, 0.15, 1.0), roughness=0.7)
    strap_black = create_material("Paski", (0.05, 0.05, 0.05, 1.0), roughness=0.9)

    # Korpus plecaka
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.9))
    body = bpy.context.active_object
    body.name = "SzkolnyPlecak"
    body.scale = (1.4, 1.0, 1.8)
    body.data.materials.append(fabric_blue)

    # Zaokrąglenie góry
    bpy.ops.mesh.primitive_cylinder_add(radius=0.7, depth=1.0, location=(0, 0, 1.8))
    top_round = bpy.context.active_object
    top_round.rotation_euler.x = math.pi / 2
    top_round.data.materials.append(fabric_blue)

    # Przednia kieszeń
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0.6, 0.7))
    pocket = bpy.context.active_object
    pocket.scale = (1.1, 0.35, 1.0)
    pocket.data.materials.append(pocket_red)

    # Szelki / paski
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

    # 2 obręcze kajdanków
    for cx in [-0.5, 0.5]:
        bpy.ops.mesh.primitive_torus_add(major_radius=0.35, minor_radius=0.07, location=(cx, 0, 0))
        cuff = bpy.context.active_object
        cuff.name = f"Obrecz_{cx}"
        cuff.data.materials.append(steel)

    # Ogniwo łączące (łańcuszek)
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

    # Korona czapki (owal)
    bpy.ops.mesh.primitive_cylinder_add(radius=0.8, depth=0.5, location=(0, 0, 0.25))
    crown = bpy.context.active_object
    crown.name = "CzapkaPolicyjna"
    crown.scale = (1.1, 1.25, 0.8)
    crown.data.materials.append(cap_blue)

    # Daszek czapki
    bpy.ops.mesh.primitive_cylinder_add(radius=0.75, depth=0.06, location=(0, 0.7, 0.05))
    visor = bpy.context.active_object
    visor.scale = (1.1, 0.8, 1.0)
    visor.rotation_euler.x = math.radians(-15)
    visor.data.materials.append(visor_black)

    # Odznaka policyjna z przodu
    bpy.ops.mesh.primitive_cylinder_add(radius=0.18, depth=0.05, location=(0, 0.85, 0.3))
    badge = bpy.context.active_object
    badge.rotation_euler.x = math.pi / 2
    badge.data.materials.append(badge_gold)

    bpy.ops.object.select_all(action='SELECT')
    bpy.context.view_layer.objects.active = crown
    bpy.ops.object.join()
    export_asset("czapka_policyjna")

def main():
    print("🚀 Rozpoczynam generowanie modeli 3D i animacji szkolnych...")
    generate_bell()
    generate_gradebook()
    generate_school_desk()
    generate_school_chair()
    generate_lockers()
    generate_pierogi_plate()
    generate_backpack()
    generate_handcuffs()
    generate_police_cap()
    print("✨ Wszystkie modele 3D i animacje zostały pomyślnie wygenerowane w folderze assets/models/!")

if __name__ == "__main__":
    main()
