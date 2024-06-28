$fn = $preview ? 32 : 64;

print_vertically = true;
clearance = 0.4;

bolt_thread_diameter = 5.8;
bolt_width_across_corners = 11.4;

nut_thickness = 4.8;
nut_width_across_corners = 11.2;

clamp_angle = 90;
clamp_arm_height = 20;
clamp_arm_width = 15;
clamp_arm_length = 90;

knob_height = 20;

module customizer_limit() {}

tiny = 0.01;
fillet = 2;
bolt_shaft_diameter = bolt_thread_diameter + clearance;
knob_inner_radius = bolt_width_across_corners * 0.75;
knob_outer_radius = bolt_width_across_corners * 1.25;

module cond_hull(enabled) {
  if (enabled)
    hull() children();
  else
    children();
}

module smooth_cylinder(h, r, f) {
  rotate_extrude() hull() {
    square([ r - f, h ]);
    translate([ r - f, f ]) circle(f);
    translate([ r - f, h - f ]) circle(f);
  }
}

module knob() {
  intersection() {
    difference() {
      gear_segments = 24;
      angular_step = 360 / gear_segments;
      gear_points =
        [for (i = [0:gear_segments - 1],
              r = i % 2 == 0 ? knob_outer_radius :
                               knob_inner_radius)[r * cos(angular_step * i),
                                                  r * sin(angular_step * i)]];

      linear_extrude(knob_height) offset(fillet / 2) offset(-fillet) offset(fillet / 2)
        polygon(gear_points);
      translate([ 0, 0, knob_height / 2 ]) cylinder(
        d = bolt_width_across_corners + clearance, h = knob_height / 2 + tiny, $fn = 6);
      translate([ 0, 0, -tiny ]) cylinder(h = knob_height, d = bolt_shaft_diameter);
    }

    smooth_cylinder(h = knob_height, r = knob_outer_radius,
                    f = knob_outer_radius - knob_inner_radius);
  }
}

module clamp_arm(length, height) {
  hull() {
    smooth_cylinder(h = height, r = clamp_arm_width / 2, f = fillet);
    translate([ length, 0 ])
      smooth_cylinder(h = height, r = clamp_arm_width / 2, f = fillet);
  }
}

module nut_slot() {
  hull() {
    cylinder(h = nut_thickness + clearance, d = nut_width_across_corners + clearance,
             $fn = 6);
    translate([ -bolt_shaft_diameter, 0 ]) cylinder(
      h = nut_thickness + clearance, d = nut_width_across_corners + clearance, $fn = 6);
  }
}

module clamp(length, has_hull, has_nut_slot, flat_back) {
  height = clamp_arm_height + bolt_shaft_diameter * 2;

  difference() {
    union() {
      clamp_arm(length = length, height = clamp_arm_height);
      rotate([ 0, 0, clamp_angle ])
        clamp_arm(length = length, height = clamp_arm_height);
      cond_hull(has_hull) {
        clamp_arm(length = clamp_arm_width, height = height);
        rotate([ 0, 0, clamp_angle ])
          clamp_arm(length = clamp_arm_width, height = height);
      }
    }

    translate([ 0, 0, clamp_arm_height + bolt_shaft_diameter - fillet / 2 ])
      rotate([ 0, 90, clamp_angle / 2 ]) {
      translate([ 0, 0, -clamp_arm_width / 2 ])
        cylinder(h = clamp_arm_width * 2, d = bolt_shaft_diameter);
      if (has_nut_slot)
        translate([ 0, 0, clamp_arm_width * cos(clamp_angle / 2) / 2 ]) nut_slot();
      if (flat_back)
        translate([ 0, 0, -clamp_arm_width / 2 ])
          cylinder(h = bolt_width_across_corners / 4, r = knob_outer_radius);
    }
  }
}

module small_clamp() {
  clamp(length = clamp_arm_length * 0.67, has_hull = true, has_nut_slot = true);
}

module big_clamp() { clamp(length = clamp_arm_length, flat_back = true); }

if ($preview) {
  bolt_length = 225 - clamp_angle;

  translate([ 0, 0, clamp_arm_height + bolt_shaft_diameter - fillet / 2 ])
    rotate([ 0, -90, clamp_angle / 2 ]) translate([ 0, 0, clamp_arm_width ]) {
    knob();
    % translate([ 0, 0, clamp_arm_height - bolt_length ])
        cylinder(h = bolt_length, d = bolt_thread_diameter);
  }
  translate([ cos(clamp_angle / 2), sin(clamp_angle / 2) ] * clamp_arm_width * 180 /
            clamp_angle) small_clamp();
  big_clamp();

} else if (print_vertically) {
  translate([ 0, 0, clamp_arm_width / 2 ]) rotate([90]) small_clamp();
  translate([ 0, 5, clamp_arm_width / 2 ]) mirror([ 0, 1, 0 ]) rotate([90]) big_clamp();
  translate([ 0, -clamp_arm_height - bolt_shaft_diameter * 2 - knob_outer_radius ])
    knob();

} else {
  translate([ cos(clamp_angle / 2), sin(clamp_angle / 2) ] * clamp_arm_width * 180 /
            clamp_angle) small_clamp();
  translate([ -cos(clamp_angle / 2), -sin(clamp_angle / 2) ] *
            (clamp_arm_width + knob_outer_radius)) knob();

  big_clamp();
}
