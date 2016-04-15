import QtQml 2.2
import QtQuick 2.6
import QtQuick.Window 2.2

import QtQuick.Layouts 1.1
import Qt.labs.controls 1.0
import Qt.labs.controls.material 1.0

Pane {
    id: grid_pane

    Rectangle {
        anchors.fill: parent

        property var angle;
        rotation: angle
        RotationAnimation on angle {
            duration: 10000
            loops: Animation.Infinite
            from: 0
            to: 360
        }

        ShaderEffect {
            width: parent.width
            height: parent.height
            blending: false

            // Line antialias area (usually 1 pixel)
            property real u_antialias : 1
            // Cartesian limits
            property var u_limits1 : Qt.vector4d(-5.1, 5.1, -5.1, 5.1)
            // Projected limits
            property var u_limits2 : Qt.vector4d(-5.0, 5.0, -5.0, 5.0)
            // Major grid steps
            property var u_major_grid_step : Qt.vector2d(1.0, 1.0)
            // Minor grid steps
            property var u_minor_grid_step : Qt.vector2d(0.1, 0.1)
            // Major grid line width (1.50 pixel)
            property real u_major_grid_width : 2.0
            // Minor grid line width (0.75 pixel)
            property real u_minor_grid_width : 1.0
            // Major grid line color
            property var u_major_grid_color : Qt.vector4d(0.0, 0.0, 0.0, 0.0)
            // Minor grid line color
            property var u_minor_grid_color : Qt.vector4d(0.5, 0.5, 0.5, 0.0)
            property var u_viewport_resolution : Qt.vector2d(width, height)

            vertexShader: "
uniform highp mat4 qt_Matrix;
attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;
varying highp vec2 v_texcoord;
void main() {
  v_texcoord = qt_MultiTexCoord0 - vec2(.5, .5);
  gl_Position = qt_Matrix * qt_Vertex;
}
"

            fragmentShader: "
// Nicolas P. Rougier (http://www.loria.fr/~rougier)
// Released under BSD license.

// Uniforms
// ------------------------------------

// Line antialias area (usually 1 pixel)
uniform float u_antialias;

// Cartesian limits
uniform vec4 u_limits1;

// Projected limits
uniform vec4 u_limits2;

// Major grid steps
uniform vec2 u_major_grid_step;

// Minor grid steps
uniform vec2 u_minor_grid_step;

// Major grid line width (1.50 pixel)
uniform float u_major_grid_width;

// Minor grid line width (0.75 pixel)
uniform float u_minor_grid_width;

// Major grid line color
uniform vec4 u_major_grid_color;

// Minor grid line color
uniform vec4 u_minor_grid_color;

// Viewport resolution
uniform vec2 u_viewport_resolution;

// Varyings
// ------------------------------------

// Texture coordinates (from (-0.5, -0.5) to (+0.5, +0.5)
varying vec2 v_texcoord;

// -------------------------------------------------
// Forward cartesian projection
vec2 transform_forward(vec2 P)
{
  return P;
}

// Inverse cartesian projection
vec2 transform_inverse(vec2 P)
{
  return P;
}
// -------------------------------------------------

// [-0.5, -0.5]x[0.5, 0.5] -> [xmin,xmax]x[ymin,ymax]
// ------------------------------------------------
vec2 scale_forward(vec2 P, vec4 limits)
{
  // limits = xmin,xmax,ymin,ymax
  P += vec2(.5, .5);
  P *= vec2(limits[1]-limits[0], limits[3]-limits[2]);
  P += vec2(limits[0], limits[2]);
  return P;
}

// [xmin,xmax]x[ymin,ymax] -> [-0.5, -0.5]x[0.5, 0.5]
// ------------------------------------------------
vec2 scale_inverse(vec2 P, vec4 limits)
{
  // limits = xmin, xmax, ymin, ymax
  P -= vec2(limits[0], limits[2]);
  P /= vec2(limits[1]-limits[0], limits[3]-limits[2]);
  return P - vec2(.5, .5);
}

// Antialias stroke alpha coeff
float stroke_alpha(float distance, float linewidth, float antialias)
{
  float t = linewidth/2.0 - antialias;
  float signed_distance = distance;
  float border_distance = abs(signed_distance) - t;
  float alpha = border_distance/antialias;
  alpha = exp(-alpha*alpha);
  if (border_distance > (linewidth/2.0 + antialias))
    return 0.0;
  else if (border_distance < 0.0)
    return 1.0;
  else
    return alpha;
}

// Compute the nearest tick from a (normalized) t value
float get_tick(float t, float vmin, float vmax, float step)
{
  float first_tick = floor((vmin + step/2.0)/step) * step;
  float last_tick = floor((vmax + step/2.0)/step) * step;
  float tick = vmin + t*(vmax-vmin);
  if (tick < (vmin + (first_tick-vmin)/2.0))
    return vmin;
  if (tick > (last_tick + (vmax-last_tick)/2.0))
    return vmax;
  tick += step/2.0;
  tick = floor(tick/step)*step;
  return min(max(vmin, tick), vmax);
}

void main()
{
  // vec2 v_texcoord;
  // if (iResolution.x > iResolution.y) {
  //   v_texcoord.x = fragCoord.x/iResolution.y - 0.5
  //     - 0.5*(iResolution.x-iResolution.y)/iResolution.y;
  //   v_texcoord.y = fragCoord.y/iResolution.y - 0.5;
  // } else {
  //   v_texcoord.x = fragCoord.x/iResolution.x - 0.5;
  //   v_texcoord.y = fragCoord.y/iResolution.x - 0.5
  //     - 0.5*(iResolution.y-iResolution.x)/iResolution.x;
  // }
  // vec2 v_size = u_viewport_resolution.xy;

  vec2 NP1 = v_texcoord;
  vec2 P1 = scale_forward(NP1, u_limits1);
  vec2 P2 = transform_inverse(P1);

  // Test if we are within limits but we do not discard yet because we want
  // to draw border. Discarding would mean half of the exterior not drawn.
  bvec2 outside = bvec2(false);
  if (P2.x < u_limits2[0]) outside.x = true;
  if (P2.x > u_limits2[1]) outside.x = true;
  if (P2.y < u_limits2[2]) outside.y = true;
  if (P2.y > u_limits2[3]) outside.y = true;

  vec2 NP2 = scale_inverse(P2, u_limits2);
  vec2 P;
  float tick;

  tick = get_tick(NP2.x+.5, u_limits2[0], u_limits2[1], u_major_grid_step[0]);
  P = transform_forward(vec2(tick, P2.y));
  P = scale_inverse(P, u_limits1);
  float Mx = length(u_viewport_resolution * (NP1 - P));
  // float Mx = screen_distance(vec4(NP1, 0, 1), vec4(P, 0, 1));

  tick = get_tick(NP2.x+.5, u_limits2[0], u_limits2[1], u_minor_grid_step[0]);
  P = transform_forward(vec2(tick, P2.y));
  P = scale_inverse(P, u_limits1);
  float mx = length(u_viewport_resolution * (NP1 - P));
  // float mx = screen_distance(vec4(NP1, 0, 1), vec4(P, 0, 1));

  tick = get_tick(NP2.y+.5, u_limits2[2], u_limits2[3], u_major_grid_step[1]);
  P = transform_forward(vec2(P2.x, tick));
  P = scale_inverse(P, u_limits1);
  float My = length(u_viewport_resolution * (NP1 - P));
  // float My = screen_distance(vec4(NP1, 0, 1), vec4(P, 0, 1));

  tick = get_tick(NP2.y+.5, u_limits2[2], u_limits2[3], u_minor_grid_step[1]);
  P = transform_forward(vec2(P2.x, tick));
  P = scale_inverse(P, u_limits1);
  float my = length(u_viewport_resolution * (NP1 - P));
  // float my = screen_distance(vec4(NP1, 0, 1), vec4(P, 0, 1));

  float M = min(Mx, My);
  float m = min(mx, my);

  // Here we take care of finishing the border lines
  if (outside.x && outside.y) {
    if (Mx > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else if (My > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else {
      M = max(Mx, My);
    }
  } else if (outside.x) {
    if (Mx > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else {
      M = m = Mx;
    }
  } else if (outside.y) {
    if (My > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else {
      M = m = My;
    }
  }

  // Mix major/minor colors to get dominant color
  vec4 color = u_major_grid_color;
  float alpha1 = stroke_alpha(M, u_major_grid_width, u_antialias);
  float alpha2 = stroke_alpha(m, u_minor_grid_width, u_antialias);
  float alpha = alpha1;
  if (alpha2 > alpha1*1.5) {
    alpha = alpha2;
    color = u_minor_grid_color;
  }

  gl_FragColor = mix(vec4(1, 1, 1, 1), color, alpha);
}
"
        }
    }
}


