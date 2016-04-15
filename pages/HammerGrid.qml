import QtQml 2.2
import QtQuick 2.6
import QtQuick.Window 2.2

import QtQuick.Layouts 1.1
import Qt.labs.controls 1.0
import Qt.labs.controls.material 1.0

Pane {
    id: hammer_grid_pane

    Rectangle {
        anchors.fill: parent

        // property var angle;
        // rotation: angle
        // RotationAnimation on angle {
        //     duration: 10000
        //     loops: Animation.Infinite
        //     from: 0
        //     to: 360
        // }

        ShaderEffect {
            width: parent.width
            height: parent.height
            blending: false

            property var u_viewport_resolution : Qt.vector2d(width, height)

            vertexShader: "
uniform highp mat4 qt_Matrix;
attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;
varying highp vec2 v_texcoord;
void main() {
  v_texcoord = qt_MultiTexCoord0; // - vec2(.5, .5);
  gl_Position = qt_Matrix * qt_Vertex;
}
"

            fragmentShader: "
// Nicolas P. Rougier (http://www.loria.fr/~rougier)
// Released under BSD license.

// Uniforms
// ------------------------------------

// Line antialias area (usually 1 pixel)
// uniform float u_antialias;

// Viewport resolution
uniform vec2 u_viewport_resolution;

// Varyings
// ------------------------------------

// Texture coordinates (from (-0.5, -0.5) to (+0.5, +0.5)
varying vec2 v_texcoord;

// ------------------------------------

// Constants
const float M_PI    = 3.14159265358979323846;
const float M_SQRT2 = 1.41421356237309504880;

// -------------------------------------------------
// Hammer forward transform
// ------------------------
vec2 transform_forward(vec2 P)
{
  const float B = 2.0;
  float longitude = P.x;
  float latitude  = P.y;
  float cos_lat = cos(latitude);
  float sin_lat = sin(latitude);
  float cos_lon = cos(longitude/B);
  float sin_lon = sin(longitude/B);
  float d = sqrt(1.0 + cos_lat * cos_lon);
  float x = (B * M_SQRT2 * cos_lat * sin_lon) / d;
  float y =     (M_SQRT2 * sin_lat) / d;
  return vec2(x,y);
}

// Hammer Inverse transform
// ------------------------
vec2 transform_inverse(vec2 P)
{
  const float B = 2.0;
  float x = P.x;
  float y = P.y;
  float z = 1.0 - (x*x/16.0) - (y*y/4.0);
  if (z < 0.0)
    discard;
  z = sqrt(z);
  float lon = 2.0*atan( (z*x),(2.0*(2.0*z*z - 1.0)));
  float lat = asin(z*y);
  return vec2(lon,lat);
}
// -------------------------------------------------

// [-0.5,-0.5]x[0.5,0.5] -> [xmin,xmax]x[ymin,ymax]
// ------------------------------------------------
vec2 scale_forward(vec2 P, vec4 limits)
{
  // limits = xmin,xmax,ymin,ymax
  P += vec2(.5,.5);
  P *= vec2(limits[1] - limits[0], limits[3]-limits[2]);
  P += vec2(limits[0], limits[2]);
  return P;
}

// [xmin,xmax]x[ymin,ymax] -> [-0.5,-0.5]x[0.5,0.5]
// ------------------------------------------------
vec2 scale_inverse(vec2 P, vec4 limits)
{
  // limits = xmin,xmax,ymin,ymax
  P -= vec2(limits[0], limits[2]);
  P /= vec2(limits[1]-limits[0], limits[3]-limits[2]);
  return P - vec2(.5,.5);
}

// Antialias stroke alpha coeff
float stroke_alpha(float distance, float linewidth, float antialias)
{
  float t = linewidth/2.0 - antialias;
  float signed_distance = distance;
  float border_distance = abs(signed_distance) - t;
  float alpha = border_distance/antialias;
  alpha = exp(-alpha*alpha);
  if( border_distance > (linewidth/2.0 + antialias) )
    return 0.0;
  else if( border_distance < 0.0 )
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
  return min(max(vmin,tick),vmax);
}

void main()
{
 float iGlobalTime = .0;

  // Cartesian limits
  vec4 u_limits1 = vec4(-3., +3., -1.5, +1.5);

  // Projected limits
  vec4 u_limits2 = vec4(-M_PI, M_PI- M_PI*(1.+cos(iGlobalTime))/2.0,
                        -M_PI/2. + (1.+cos(iGlobalTime))/2.*M_PI/4.,
                        +M_PI/2. - (1.+cos(iGlobalTime/2.))/2.*M_PI/4.);

  const float u_antialias = 1.0;
  vec2 u_major_grid_step = vec2(M_PI/4.0,  M_PI/6.0);
  vec2 u_minor_grid_step = vec2(M_PI/40.0, M_PI/60.0);
  float u_major_grid_width = 2.00;
  float u_minor_grid_width = 1.00;
  vec4  u_major_grid_color = vec4(0,0,0,1);
  vec4  u_minor_grid_color = vec4(0,0,0,1);

  vec2 v_texcoord = v_texcoord.xy; // / u_viewport_resolution.xy - 0.5;
  vec2 v_size = u_viewport_resolution.xy;

  vec2 NP1 = v_texcoord;
  vec2 P1 = scale_forward(NP1, u_limits1);
  vec2 P2 = transform_inverse(P1);

  // Test if we are within limits but we do not discard yet because we want
  // to draw border. Discarding would mean half of the exterior not drawn.
  bvec2 outside = bvec2(false);
  if( P2.x < u_limits2[0] ) outside.x = true;
  if( P2.x > u_limits2[1] ) outside.x = true;
  if( P2.y < u_limits2[2] ) outside.y = true;
  if( P2.y > u_limits2[3] ) outside.y = true;

  vec2 NP2 = scale_inverse(P2,u_limits2);
  vec2 P;
  float tick;

  tick = get_tick(NP2.x+.5, u_limits2[0], u_limits2[1], u_major_grid_step[0]);
  P = transform_forward(vec2(tick,P2.y));
  P = scale_inverse(P, u_limits1);
  float Mx = length(v_size * (NP1 - P));
  // float Mx = screen_distance(vec4(NP1,0,1), vec4(P,0,1));


  tick = get_tick(NP2.x+.5, u_limits2[0], u_limits2[1], u_minor_grid_step[0]);
  P = transform_forward(vec2(tick,P2.y));
  P = scale_inverse(P, u_limits1);
  float mx = length(v_size * (NP1 - P));
  // float mx = screen_distance(vec4(NP1,0,1), vec4(P,0,1));

  tick = get_tick(NP2.y+.5, u_limits2[2], u_limits2[3], u_major_grid_step[1]);
  P = transform_forward(vec2(P2.x,tick));
  P = scale_inverse(P, u_limits1);
  float My = length(v_size * (NP1 - P));
  // float My = screen_distance(vec4(NP1,0,1), vec4(P,0,1));

  tick = get_tick(NP2.y+.5, u_limits2[2], u_limits2[3], u_minor_grid_step[1]);
  P = transform_forward(vec2(P2.x,tick));
  P = scale_inverse(P, u_limits1);
  float my = length(v_size * (NP1 - P));
  // float my = screen_distance(vec4(NP1,0,1), vec4(P,0,1));

  float M = min(Mx,My);
  float m = min(mx,my);

  // Here we take care of finishing the border lines
  if( outside.x && outside.y ) {
    if (Mx > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else if (My > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else {
      M = max(Mx,My);
    }
  } else if( outside.x ) {
    if (Mx > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else {
      M = m = Mx;
    }
  } else if( outside.y ) {
    if (My > 0.5*(u_major_grid_width + u_antialias)) {
      gl_FragColor = vec4(1); return;
    } else {
      M = m = My;
    }
  }

  // Mix major/minor colors to get dominant color
  vec4 color = u_major_grid_color;
  float alpha1 = stroke_alpha( M, u_major_grid_width, u_antialias);
  float alpha2 = stroke_alpha( m, u_minor_grid_width, u_antialias);
  float alpha  = alpha1;
  if( alpha2 > alpha1*1.5 )
    {
      alpha = alpha2;
      color = u_minor_grid_color;
    }

  // At no extra cost we can also project a texture
  // if( outside.x || outside.y ) {
  //   gl_FragColor = mix(vec4(1,1,1,1), color, alpha);
  // } else {
  //   vec4 texcolor = texture2D(iChannel0, vec2(NP2.x+0.5, NP2.y+0.5));
  //   gl_FragColor = mix(texcolor, color, color.a*alpha);
  // }
  gl_FragColor = mix(vec4(1,1,1,1), color, alpha);
}
"
        }
    }
}


