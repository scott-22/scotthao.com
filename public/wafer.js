// Shades "pixels" on the silicon wafer header. Each pixel is a 2x2 block
// of wafer cells. Pixel shading is controlled programmatically.

import { GRID } from './wafer-grid.js';
import { IMAGE } from './wafer-image.js';

const CELLS_PER_PIXEL = 2;
export const TICKS_PER_SECOND = 16;

// Types of pixel shading
export const FLAT = 1;
export const STITCH = 2;

// Seed for random generator
const SEED = Math.floor(Date.now() / 1000);

const VERTEX = `#version 300 es
out vec2 vUv;
void main() {
  // One triangle covering the canvas; vUv is (0,0) at the photo's top left.
  vec2 corner = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
  vUv = vec2(corner.x, 1.0 - corner.y);
  gl_Position = vec4(corner * 2.0 - 1.0, 0.0, 1.0);
}`;

const FRAGMENT = `#version 300 es
precision highp float;
uniform sampler2D uState;  // per pixel: colour in rgb, style in alpha (0 = off)
uniform vec2 uWarp[10];    // photo position -> wafer cell, see wafer-grid.js
in vec2 vUv;
out vec4 outColor;

float random_vec(vec2 st) {
  return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

uint hash(uint x) {
  x ^= x >> 16; x *= 0x7feb352dU;
  x ^= x >> 15; x *= 0x846ca68bU;
  x ^= x >> 16;
  return x;
}

float random_ivec(ivec2 id) {
  uint h = hash(uint(id.x) ^ hash(uint(id.y) ^ hash(${SEED}u)));
  return float(h >> 8) / 16777216.0;
}

float noise(vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);

  float a = random_vec(i);
  float b = random_vec(i + vec2(1.0, 0.0));
  float c = random_vec(i + vec2(0.0, 1.0));
  float d = random_vec(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3.0 - 2.0 * f);

  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Calculate the grid position from the screen position using the fitted polynomials
vec2 cellAt(vec2 uv) {
  float x = 2.0 * uv.x - 1.0, y = 2.0 * uv.y - 1.0;
  return uWarp[0] + y * (uWarp[1] + y * (uWarp[2] + y * uWarp[3]))
       + x * (uWarp[4] + y * (uWarp[5] + y * uWarp[6])
       + x * (uWarp[7] + y * uWarp[8]
       + x * uWarp[9]));
}

// Calculate how much point p is covered by a strand of thread from a to b,
// px is the size of a screen pixel (for antialiasing)
float strand(vec2 p, vec2 a, vec2 b, float radius, float px) {
  vec2 ab = b - a;
  float t = clamp(dot(p - a, ab) / dot(ab, ab), 0.0, 1.0);
  return clamp((radius - distance(p, a + ab * t)) / px * 0.3 + 0.6, 0.0, 1.0);
}

// Color of a screen pixel for a stitch. p is the normalized coordinate within
// the grid, and px is the corresponding (normalized) size of a screen pixel
vec4 stitch(vec3 color, vec2 p, float px, int stitch_type) {
  vec2 uv = fract(p);
  vec4 result;

  float radius = (stitch_type > 0) ? 0.13 : 0.14;
  // Apply noise to fuzz edges
  vec2 delta = vec2(noise(p) - 0.5, noise(p + 1.0) - 0.5) * 0.2;
  float cover, shadow = 1.0;
  if (stitch_type == 0) {
    // Diagonal. Choose one stitch at random to go over the other one
    float y = random_vec(floor(p)) > 0.5 ? 0.2 : 0.8;
    vec2 over_a = vec2(0.2, y) + delta, over_b = vec2(0.8, 1.0 - y) + delta;
    vec2 under_a = vec2(0.2, 1.0 - y) + delta, under_b = vec2(0.8, y) + delta;
    float over = strand(uv, over_a, over_b, radius, px);
    float under = strand(uv, under_a, under_b, radius, px);
    cover = max(over, under);
    float over_mask = clamp((0.8 - over) / 0.3 + 0.5, 0.0, 1.0);
    shadow = 1.0 - 0.3 * under * over_mask * strand(uv, over_a, over_b, radius + 0.02, 0.02);
  } else if (stitch_type == 1) {
    // Horizontal
    cover = max(strand(uv, vec2(0.2, 0.25) + delta, vec2(0.8, 0.25) + delta, radius, px),
                strand(uv, vec2(0.2, 0.75) + delta, vec2(0.8, 0.75) + delta, radius, px));
  } else {
    // Vertical
    cover = max(strand(uv, vec2(0.25, 0.2) + delta, vec2(0.25, 0.8) + delta, radius, px),
                strand(uv, vec2(0.75, 0.2) + delta, vec2(0.75, 0.8) + delta, radius, px));
  }
  // Keep not-too-dark colors full opacity to give dark borders
  if (cover < 0.6) result = vec4(color, 1.3) * cover;
  else result = vec4(color * cover, 1.0);
  result.rgb *= shadow;

  // Apply stripe noise
  vec2 centered = uv - 0.5;
  float stripe;
  if (stitch_type == 1) {
    stripe = noise(vec2(p.x + centered.x * 16.0, p.y + centered.y));
  } else {
    stripe = noise(vec2(p.x + centered.x, p.y + centered.y * 16.0));
  }
  result.rgb *= (1.0 + (min(stripe - 0.3, 0.3)) * 0.25);

  return result;
}

// Color of a screen pixel for a flat tile. uv is a coordinate within the pixel
// normalized from 0 to 1, and px is the corresponding size of a screen pixel
vec4 square(vec3 color, vec2 uv, float px) {
  float cover = clamp(min(min(uv.x, uv.y), min(1.0 - uv.x, 1.0 - uv.y)) / px * 0.45 + 0.1, 0.0, 1.0);
  return vec4(color * cover, 1.0);
}

void main() {
  vec2 p = cellAt(vUv) / float(${CELLS_PER_PIXEL});  // position on the pixel grid
  float px = fwidth(p.x);
  ivec2 id = ivec2(floor(p));
  ivec2 size = textureSize(uState, 0);
  outColor = vec4(0.0);
  if (id.x < 0 || id.y < 0 || id.x >= size.x || id.y >= size.y) return;

  vec4 state = texelFetch(uState, id, 0);
  int style = int(state.a * 255.0 + 0.5);
  if (style == ${FLAT}) {
    outColor = square(state.rgb, fract(p), px);
  } else if (style == ${STITCH}) {
    int stitch_type = int(random_ivec(id) * 3.0);
    outColor = stitch(state.rgb, p, px, stitch_type);
  }
}`;

function compile(gl, type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    throw new Error(gl.getShaderInfoLog(shader));
  }
  return shader;
}

export class Wafer {
  cols = Math.ceil(GRID.cols / CELLS_PER_PIXEL);
  rows = Math.ceil(GRID.rows / CELLS_PER_PIXEL);
  tick = 0;

  #canvas;
  #gl;
  #state = new Uint8Array(this.cols * this.rows * 4);
  #dirty = true;
  #tasks = [];
  #frame = 0;
  #lastTick = 0;
  #visible = true;

  // Throws if WebGL 2 is unavailable; the photo is then simply left as it is.
  constructor(canvas) {
    this.#canvas = canvas;
    const gl = this.#gl = canvas.getContext('webgl2', { antialias: false });
    if (!gl) throw new Error('WebGL 2 is not available');

    const program = gl.createProgram();
    gl.attachShader(program, compile(gl, gl.VERTEX_SHADER, VERTEX));
    gl.attachShader(program, compile(gl, gl.FRAGMENT_SHADER, FRAGMENT));
    gl.linkProgram(program);
    if (!gl.getProgramParameter(program, gl.LINK_STATUS)) {
      throw new Error(gl.getProgramInfoLog(program));
    }
    gl.useProgram(program);
    gl.uniform2fv(
      gl.getUniformLocation(program, 'uWarp'),
      GRID.warpX.flatMap((x, k) => [x, GRID.warpY[k]]),
    );

    gl.bindTexture(gl.TEXTURE_2D, gl.createTexture());
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

    new ResizeObserver(([entry]) => {
      const box = entry.devicePixelContentBoxSize?.[0];
      canvas.width = box?.inlineSize ?? Math.round(entry.contentRect.width * devicePixelRatio);
      canvas.height = box?.blockSize ?? Math.round(entry.contentRect.height * devicePixelRatio);
      this.#draw();  // resizing clears the canvas
    }).observe(canvas);

    new IntersectionObserver(([entry]) => {
      this.#visible = entry.isIntersecting;
      this.#schedule();
    }).observe(canvas);
  }

  // Light the pixel at (x, y). `color` is [r, g, b], each 0-255.
  // Coordinates off the grid are ignored, so shapes may overhang the edges.
  set(x, y, color, style = STITCH) {
    if (x < 0 || y < 0 || x >= this.cols || y >= this.rows) return;
    this.#state.set([color[0], color[1], color[2], style], (y * this.cols + x) * 4);
    this.#dirty = true;
  }

  // Return the pixel at (x, y) to the photo.
  clear(x, y) {
    this.set(x, y, [0, 0, 0], 0);
  }

  // Run a program: an iterator, usually from a generator, that sets and clears
  // pixels and yields how many ticks to wait before it is resumed (default 1).
  // Programs run concurrently, and may spawn others.
  spawn(program) {
    this.#tasks.push({ program, wake: this.tick });
    this.#schedule();
  }

  #schedule() {
    if (this.#visible && this.#tasks.length && !this.#frame) {
      this.#frame = requestAnimationFrame(this.#onFrame);
    }
  }

  #onFrame = (now) => {
    this.#frame = 0;
    const tickMs = 1000 / TICKS_PER_SECOND;
    if (now - this.#lastTick >= tickMs) {
      // Keep to the beat, but never run a burst of ticks to catch up.
      this.#lastTick = Math.max(this.#lastTick + tickMs, now - tickMs);
      this.#step();
    }
    if (this.#dirty) this.#draw();
    this.#schedule();
  };

  #step() {
    const tasks = this.#tasks;
    this.#tasks = [];  // programs spawned during this tick land here
    for (const task of tasks) {
      if (task.wake <= this.tick) {
        const { done, value } = task.program.next();
        if (done) continue;
        task.wake = this.tick + Math.max(1, value ?? 1);
      }
      this.#tasks.push(task);
    }
    this.tick++;
  }

  #draw() {
    const gl = this.#gl;
    gl.viewport(0, 0, this.#canvas.width, this.#canvas.height);
    gl.texImage2D(
      gl.TEXTURE_2D, 0, gl.RGBA, this.cols, this.rows, 0,
      gl.RGBA, gl.UNSIGNED_BYTE, this.#state,
    );
    gl.drawArrays(gl.TRIANGLES, 0, 3);
    this.#dirty = false;
  }
}

// ---------------------------------------------------------------------------
// Programs
// ---------------------------------------------------------------------------

const hex = (s) => [1, 3, 5].map((i) => parseInt(s.slice(i, i + 2), 16));
const rand = (lo, hi) => lo + Math.random() * (hi - lo);
const randInt = (lo, hi) => Math.floor(rand(lo, hi + 1));
const pick = (items) => items[randInt(0, items.length - 1)];

const INK = Object.fromEntries(Object.entries({
  w: '#e4e4e7', s: '#a1a1aa', g: '#71717a', k: '#3f3f46',  // greys, light to dark
  y: '#e6cf97', t: '#d4b06a', b: '#b88a3e',                // tans, light to dark
  r: '#b3261e',                                            // yarn red
  c: '#0891b2',                                            // cyan
}).map(([ch, color]) => [ch, hex(color)]));

// Approximate lifetime of pixel in seconds
const LIFETIME = 10;

// Run [tick, action] events in order of tick.
function* timeline(events) {
  let now = 0;
  for (const [tick, action] of events.sort((a, b) => a[0] - b[0])) {
    if (tick > now) {
      yield tick - now;
      now = tick;
    }
    action();
  }
}

const PICTURE_SEEDS = 3;    // Number of points the picture fills from
const PICTURE_SPREAD = 12;  // Number of ticks for animation to complete

// Show a picture (rows of characters, one per pixel, top row first).
function* picture(wafer, rows) {
  const pixels = [];
  rows.forEach((row, y) => [...row].forEach((ch, x) => {
    const color = INK[ch.toLowerCase()];
    if (color) pixels.push({ x, y, color, style: ch === ch.toLowerCase() ? STITCH : FLAT });
  }));
  if (!pixels.length) return;

  // How far each pixel is from the nearest seed.
  const seeds = Array.from({ length: PICTURE_SEEDS }, () => pick(pixels));
  const far = pixels.map((p) => Math.min(...seeds.map((s) => Math.hypot(p.x - s.x, p.y - s.y))));
  const furthest = Math.max(...far, 1);

  const grow = [], shrink = [];
  pixels.forEach(({ x, y, color, style }, i) => {
    const d = far[i] / furthest;
    grow.push([Math.round(d * PICTURE_SPREAD) + randInt(0, 2), () => wafer.set(x, y, color, style)]);
    shrink.push([Math.round((1 - d) * PICTURE_SPREAD) + randInt(0, 2), () => wafer.clear(x, y)]);
  });

  yield* timeline(grow);
  yield LIFETIME * TICKS_PER_SECOND - PICTURE_SPREAD;
  yield* timeline(shrink);
}

const canvas = document.getElementById('wafer');
if (canvas && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
  const wafer = new Wafer(canvas);
  wafer.spawn(picture(wafer, IMAGE));
}
