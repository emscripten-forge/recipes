/*
 * Copyright (c) 2013 Google, Inc.
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 1. The origin of this software must not be misrepresented; you must not
 * claim that you wrote the original software. If you use this software
 * in a product, an acknowledgment in the product documentation would be
 * appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

// Scales the particle to the correct size. All the fun happens in point.ps

attribute vec4 position;       // in 2d worldspace
attribute float particlesize;  // scale relative to physical size of 1

uniform vec2 extents;          // worldspace -> clipspace scale
uniform float scale;           // number of pixels of 1 world unit

void main() {
  gl_Position = vec4(position.xy / extents, 0.0, 1.0);
  gl_PointSize = scale * particlesize;
}
