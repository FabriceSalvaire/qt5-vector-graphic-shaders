import QtQml 2.2
import QtQuick 2.6
import QtQuick.Window 2.2

import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0

Pane {
    id: quadratic_bezier_pane

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
uniform vec2 u_viewport_resolution;
uniform highp mat4 qt_Matrix;
attribute highp vec4 qt_Vertex;
attribute highp vec2 qt_MultiTexCoord0;
varying highp vec2 v_texcoord;
void main() {
  v_texcoord = qt_MultiTexCoord0 * u_viewport_resolution;
  gl_Position = qt_Matrix * qt_Vertex;
}
"

            fragmentShader: "
// Intel
// 0:34(54): error: arrays cannot be out or inout parameters in GLSL 1.10 (GLSL 1.20 or GLSL ES 1.00 required)

// Subpixels antialiased quadratic Bézier stroke curve with butt caps and self-cover
// Nicolas P. Rougier (http://www.loria.fr/~rougier)
// Released under BSD license.

// #version 120

// Uniforms

// Line antialias area (usually 1 pixel)
// uniform float u_antialias;

// Viewport resolution
uniform vec2 u_viewport_resolution;

// Varyings

// Texture coordinates (from (-0.5, -0.5) to (+0.5, +0.5)
varying vec2 v_texcoord;

float
cubic_root(float x)
{
  if( x < 0.0 )
    return -pow(-x, 1.0/3.0);
  return pow(x, 1.0/3.0);
}

int
cubic_solve(in float a, in float b, in float c, out float r[3])
{
  float  p = b - a*a / 3.0;
  float  q = a * (2.0*a*a - 9.0*b) / 27.0 + c;
  float p3 = p*p*p;
  float  d = q*q + 4.0*p3 / 27.0;
  float offset = -a / 3.0;
  if (d >= 0.0) {
      float z = sqrt(d);
      float u = (-q + z) / 2.0;
      float v = (-q - z) / 2.0;
      u = cubic_root(u);
      v = cubic_root(v);
      r[0] = offset + u + v;
      return 1;
  }
  float u = sqrt(-p / 3.0);
  float v = acos(-sqrt( -27.0 / p3) * q / 2.0) / 3.0;
  float m = cos(v), n = sin(v)*1.732050808;
  r[0] = offset + u * (m + m);
  r[1] = offset - u * (n + m);
  r[2] = offset + u * (n - m);
  return 3;
}

void main()
{
  float iGlobalTime = .0;

  vec2 _p0 = vec2(0.25, .5) * u_viewport_resolution.xy;
  vec2 _p1 = vec2(.5 + .5*cos(iGlobalTime*.3), .75 + .5*sin(5.+iGlobalTime)) * u_viewport_resolution.xy;
  vec2 _p2 = vec2(.75, .5) * u_viewport_resolution.xy;

  float linewidth = 100.0 + cos(iGlobalTime)*50.0;
  float antialias = 1.0;
  vec3 color = vec3(.75,.75,1.0);

  vec2 _position = v_texcoord.xy;

  vec2  sb = (_p1 - _p0) * 2.0;
  vec2  sc = _p0 - _p1 * 2.0 + _p2;
  vec2  sd = _p1 - _p0;
  float sA = 1.0 / dot(sc, sc);
  float sB = 3.0 * dot(sd, sc);
  float sC = 2.0 * dot(sd, sd);
  vec2  D = _p0 - _position;
  float res[3];
  int n = cubic_solve(sB*sA, (sC+dot(D,sc))*sA, dot(D,sd)*sA, res);

  float t0 = res[0];
  // float t0 = clamp(res[0], 0.0, 1.0);
  bool ct0 = (t0 >= 0.0) && (t0 <= 1.0);
  vec2 pos = _p0 + (sb + sc*t0)*t0;
  float d0 = length(pos - _position);

  float d = 1e20;

  if (n > 1) {
      float t1 = res[1];
      // float t1 = clamp(res[1], 0.0, 1.0);
      bool ct1 = (t1 >= 0.0) && (t1 <= 1.0);
      pos = _p0 + (sb + sc*t1)*t1;
      float d1 = length(pos - _position);

      float t2 = res[2];
      // float t2 = clamp(res[2],0.0,1.0);
      bool ct2 = (t2>=0.0) && (t2<=1.0);
      pos = _p0 + (sb + sc*t2)*t2;
      float d2 = length(pos - _position);

      if( ct0 && ct1 && ct2 ) {
          d =  min(min(d0,d1),d2) - linewidth/2.0;
      } else {
          if (ct0 && ct1 && !ct2) {
              float maxd0d1 = max(d0,d1);
              if ( maxd0d1 < (linewidth/2.0 + 0.5*antialias))
                d = linewidth/2.0 - maxd0d1 - 0.5*antialias;
              else
                d = min(d0,d1) - linewidth/2.0 + antialias;
            }
          else if (ct1 && ct2 && !ct0) {
              float maxd1d2 = max(d1,d2);
              if ( maxd1d2 < (linewidth/2.0 + 0.5* antialias))
                d =  linewidth/2.0 - maxd1d2 - 0.5* antialias;
              else
                d = min(d1,d2) - linewidth/2.0;
            } else if( ct2 && ct0 && !ct1 ) {
              float maxd2d0 = max(d2,d0);
              if ( maxd2d0 < (linewidth/2.0 + 0.5* antialias))
                d = linewidth/2.0 - maxd2d0 - 0.5* antialias;
              else
                d =  min(d2,d0) - linewidth/2.0;
            } else {
              if( ct0 && (d0 < d) ) d = d0;
              if( ct1 && (d1 < d) ) d = d1;
              if( ct2 && (d2 < d) ) d = d2;
              d =  d - linewidth/2.0;
            }
        }
    }
  else {
      if (ct0)
        d = d0 - linewidth/2.0;
    }

  // Butt cap at start
  {
    float l = dot(_p1-_p0,_p1-_p0);
    float u =( (_position.x-_p0.x)*(_p1.x-_p0.x) + (_position.y-_p0.y)*(_p1.y-_p0.y) ) / l;
    vec2 p = _p0 + u*(_p1-_p0);
    float d1 = length(p-_p0);
    float d2 = length(_position-p);
    //d = min(d, max(d2-_thickness/2.0  + _antialiased, d1)); // - _antialiased));
    d = min(d, max(d2-linewidth/2.0, d1 - antialias));
  }

  // Butt cap at end
  {
    float l = dot(_p1-_p2,_p1-_p2);
    float u =( (_position.x-_p2.x)*(_p1.x-_p2.x) + (_position.y-_p2.y)*(_p1.y-_p2.y) ) / l;
    vec2 p = _p2 + u*(_p1-_p2);
    float d1 = length(p - _p2);
    float d2 = length(_position - p);
    // d = min(d, max(d2-_thickness/2.0  + _antialiased, d1)); // - _antialiased));
    d = min(d, max(d2-linewidth/2.0, d1 - antialias));
  }

  d += antialias;

  if( d < 0.0 ) {
      gl_FragColor.rgb = color;
    } else {
      float alpha = d/antialias;
      alpha = exp(-alpha*alpha);
      gl_FragColor = vec4(color*alpha, 1.0);
    }
}
"
        }
    }
}


