/*
  Copyright (C) 2013 John McCutchan <john@johnmccutchan.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

part of spectre_renderer;

/**
 * The renderable class contains everything needed to render a mesh instance.
 * TODO(johnmccutchan): Factor this into a base interface and implement
 * MeshRenderable.
 */
class Renderable {
  final Renderer renderer;
  final String name;
  Map<String, String> _materialPaths;
  Map<String, Material> materials;
  mat4 T = new mat4.identity();

  /// Path to mesh asset.
  String get meshPath => _meshPath;
  void set meshPath(String o) {
    _meshPath = o;
    mesh = renderer.assetManager[_meshPath];
  }
  String _meshPath;

  /// Path to material asset.
  String get materialPath => _materialPath;
  set materialPath(String o) {
    _materialPath = o;
    material = renderer.assetManager[_materialPath];
  }
  String _materialPath;

  InputLayout get inputLayout => _inputLayout;
  InputLayout _inputLayout;
  // Bounding Box.

  Renderable(this.name, this.renderer, this._meshPath, this._materialPaths) {
    _inputLayout = new InputLayout(name, renderer.device);
    mesh = renderer.assetManager[_meshPath];
    _link();
  }

  Renderable.json(Map json, this.renderer) : name = json['name'] {
    _inputLayout = new InputLayout(name, renderer.device);
    fromJson(json);
    _link();
  }

  void cleanup() {
    _inputLayout.dispose();
  }

  SpectreMesh get mesh => _mesh;
  set mesh(SpectreMesh m) {
    _mesh = m;
    _link();
  }
  SpectreMesh _mesh;

  Material get material => _material;
  set material(Material m) {
    _material = m;
    _link();
  }
  Material _material;

  void _link() {
    _inputLayout.mesh = _mesh;
    if (_material != null) {
      _inputLayout.shaderProgram = _material.shader;
    }
  }

  void render(Layer layer, Camera camera) {
    if (_material == null) {
      spectreLog.Error('Cannot render $name it has no material.');
      return;
    }
    if (_mesh == null) {
      spectreLog.Error('Cannot render $name it has no mesh.');
      return;
    }
    if (_inputLayout.ready == false) {
      spectreLog.Error('Cannot render $name inputs are invalid.');
      return;
    }
    _material.updateCameraConstants(camera);
    _material.updateObjectTransformConstant(T);
    renderer._applyMaterial(_material);
    renderer.device.context.setInputLayout(_inputLayout);
    renderer.device.context.setIndexedMesh(_mesh);
    renderer.device.context.drawIndexedMesh(_mesh);
  }

  void fromJson(Map json) {
    meshPath = json['meshPath'];
    materialPath = json['materialPath'];
    T.copyFromArray(json['T']);
  }

  dynamic toJson() {
    Map map = new Map();
    map['name'] = name;
    map['meshPath'] = meshPath;
    map['materialPath'] = materialPath;
    map['T'] = new List<num>();
    T.copyIntoArray(map['T']);
    return map;
  }
}
