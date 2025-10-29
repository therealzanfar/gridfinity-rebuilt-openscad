// ===== INFORMATION ===== //
/*
 IMPORTANT: rendering will be better in development builds and not the official release of OpenSCAD, but it makes rendering only take a couple seconds, even for comically large bins.
 the magnet holes can have an extra cut in them to make it easier to print without supports
 tabs will automatically be disabled when gridz is less than 3, as the tabs take up too much space
 base functions can be found in "gridfinity-rebuilt-utility.scad"
 comments like ' //.5' after variables are intentional and used by the customizer
 examples at end of file

 #BIN HEIGHT
 The original gridfinity bins had the overall height defined by 7mm increments.
 A bin would be 7*u millimeters tall with a stacking lip at the top of the bin (4.4mm) added onto this height.
 The stock bins have unit heights of 2, 3, and 6:
 * Z unit 2 -> 7*2 + 4.4 -> 18.4mm
 * Z unit 3 -> 7*3 + 4.4 -> 25.4mm
 * Z unit 6 -> 7*6 + 4.4 -> 46.4mm

 ## Note:
 The stacking lip provided here has a 0.6mm fillet instead of coming to a sharp point.
 Which has a height of 3.55147mm instead of the specified 4.4mm.
 This **has no impact on stacking height, and can be ignored.**

https://github.com/kennetek/gridfinity-rebuilt-openscad
*/

include <src/core/standard.scad>
use <src/core/gridfinity-rebuilt-utility.scad>
use <src/core/gridfinity-rebuilt-holes.scad>
use <src/core/bin.scad>
use <src/core/cutouts.scad>
use <src/helpers/generic-helpers.scad>
use <src/helpers/grid.scad>
use <src/helpers/shapes.scad>
use <src/helpers/grid_element.scad>
use <src/helpers/generic-helpers.scad>
use <src/core/gridfinity-baseplate.scad>

// ===== PARAMETERS ===== //

/* [Setup Parameters] */
$fa = 4;
$fs = 0.25; // .01

/* [General Settings] */
// number of bases along x-axis
gridx = 3;
// number of bases along y-axis
gridy = 2;
// bin height. See bin height information and "gridz_define" below.
gridz = 6; //.1

/* [Cap Settings] */
// Should the block be empty inside so it can fit over obstacles?
hollow = true;
// Should the block include all grid seperators?
//bridge = true;

// Vestigial options that were removed from the configurator.
/* [Hidden] */
divx = 0;
divy = 0;
half_grid = false;
only_corners = false;
refined_holes = false;
magnet_holes = false;
screw_holes = false;
crush_ribs = false;
chamfer_holes = false;
printable_hole_top = false;
enable_thumbscrew = false;

gridz_define = 0;
enable_zsnap = false;
height_internal = 0;
include_lip = true;

hole_options = bundle_hole_options(refined_holes, magnet_holes, screw_holes, crush_ribs, chamfer_holes, printable_hole_top);

// Cosntants that won't import, probably becuase I suck at OpenSCAD.
BASEPLATE_HEIGHT = 5;           // gridfinity-baseplate.scad
BASEPLATE_LOWER_RADIUS = 2.6;   // gridfinity-baseplate.scad; _BASEPLATE_PROFILE[3][1]
BASEPLATE_OUTER_RADIUS = 4;     // gridfinity-baseplate.scad
BIN_Z_LIP_OFFSET = 4.4;         // ? but it has to be defined somewhere...


// ===== IMPLEMENTATION ===== //

bin1 = new_bin(
    grid_size = [gridx, gridy],
    height_mm = height(gridz, gridz_define, enable_zsnap),
    fill_height = height_internal,
    include_lip = include_lip,
    hole_options = hole_options,
    only_corners = only_corners || half_grid,
    thumbscrew = enable_thumbscrew,
    grid_dimensions = GRID_DIMENSIONS_MM / (half_grid ? 2 : 1)
);

echo(str(
    "\n",
    "Infill Dimensions*: ", bin_get_infill_size_mm(bin1), "\n",
    "Bounding Box: ", bin_get_bounding_box(bin1), "\n",
    "  *Excludes Stacking Lip Support Height (if stacking lip enabled)\n",
));
echo("Height breakdown:");
pprint(bin_get_height_breakdown(bin1));

bounds = bin_get_bounding_box(bin1);

// Remove the core of the bin.
difference() {
    bin_render(bin1) {
    }

    if (hollow) {
        linear_extrude(bounds[2])
        rounded_square([
                GRID_DIMENSIONS_MM.x*gridx - BASE_GAP_MM.x - BASEPLATE_LOWER_RADIUS*2,
                GRID_DIMENSIONS_MM.y*gridy - BASE_GAP_MM.y - BASEPLATE_LOWER_RADIUS*2
            ],
            BASEPLATE_OUTER_RADIUS - BASE_GAP_MM.x/2 - BASEPLATE_LOWER_RADIUS,
            center = true);
    }
};

// Build the top baseplate
    difference() {
        // The baseplate blank.
        translate([0,0,bounds[2]-BASEPLATE_HEIGHT])
        linear_extrude(BASEPLATE_HEIGHT)
        rounded_square(
            [
                GRID_DIMENSIONS_MM.x*gridx - BASE_GAP_MM.x - BASEPLATE_LOWER_RADIUS*2,
                GRID_DIMENSIONS_MM.y*gridy - BASE_GAP_MM.y - BASEPLATE_LOWER_RADIUS*2
            ],
            BASEPLATE_OUTER_RADIUS,
            center = true);
            

        for (bx = [0:gridx-1]) {
            for (by = [0:gridy-1]) {
                translate([
                    (-GRID_DIMENSIONS_MM.x*(gridx-1))/2 + bx*GRID_DIMENSIONS_MM.x,
                    (-GRID_DIMENSIONS_MM.y*(gridy-1))/2 + by*GRID_DIMENSIONS_MM.y,
                    bounds[2]-BASEPLATE_HEIGHT])
                baseplate_cutter();
            }
        }
    };