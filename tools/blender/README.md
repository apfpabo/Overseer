# Blender art-test scripts

These rendered the lighting test the owner approved (see `docs/DECISIONS.md` D-004).
They aren't part of the game build. Keep them as reference for the look: materials, colors, light setup, the isometric camera angle.

- `render3d_lit.py`: builds the test room and crew from boxes and renders them with Cycles. Run with Python that has the `bpy` package: `python render3d_lit.py OUT_DIR`.
- `pixel_lit.py`: post-processing (hard edges, color reduction, sprite outline and shadow).
