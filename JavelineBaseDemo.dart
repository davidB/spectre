/*

  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>

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


class JavelineDemoStatus {
  static final int DemoStatusOKAY = 0;
  static final int DemoStatusError = 1;
  JavelineDemoStatus(this.code, this.text);
  int code;
  String text;
}


class JavelineBaseDemo {
  JavelineKeyboard _keyboard;
  JavelineMouse _mouse;
  num _time;
  num _oldTime;
  num _accumTime;
  num _lastYaw;
  num _lastPitch;
  int _viewPort;
  int _blendState;
  int _depthState;
  int _rasterizerState;

  Device _device;
  ImmediateContext _immediateContext;
  ResourceManager _resourceManager;
  DebugDrawManager _debugDrawManager;
  
  Device get device() => _device;
  ImmediateContext get immediateContext() => _immediateContext;
  DebugDrawManager get debugDrawManager() => _debugDrawManager;
  ResourceManager get resourceManager() => _resourceManager;
  
  bool _quit;
  Camera _camera;
  MouseKeyboardCameraController _cameraController;

  int width;
  int height;

  JavelineBaseDemo(Device device, ResourceManager resourceManager, DebugDrawManager debugDrawManager) {
    _device = device;
    _immediateContext = device.immediateContext;
    _resourceManager = resourceManager;
    _debugDrawManager = debugDrawManager;
    
    _keyboard = new JavelineKeyboard();
    _mouse = new JavelineMouse();
    _camera = new Camera();
    _camera.eyePosition = JavelineConfigStorage.get('camera.eyePosition');
    _camera.lookAtPosition = JavelineConfigStorage.get('camera.lookAtPosition');
    _cameraController = new MouseKeyboardCameraController();
    _quit = false;
    _time = 0;
    _oldTime = 0;
    _accumTime = 0;
    _lastYaw = 0;
    _lastPitch = 0;
  }

  void resize(num elementWidth, num elementHeight) {
    this.width = elementWidth;
    this.height = elementHeight;
    Viewport vp = _device.getDeviceChild(_viewPort);
    if (vp == null) {
      return;
    }
    vp.width = elementWidth;
    vp.height = elementHeight;
    print('Resized to $elementWidth $elementHeight');
  }

  Future<JavelineDemoStatus> startup() {
    Completer<JavelineDemoStatus> completer = new Completer();
    JavelineDemoStatus status = new JavelineDemoStatus(JavelineDemoStatus.DemoStatusOKAY, 'Base OKAY');
    completer.complete(status);
    {
      _viewPort = _device.createViewport('Default VP', {'x':0, 'y':0, 'width':width, 'height':height});
      _blendState = _device.createBlendState('Default BS', {});
      _depthState = _device.createDepthState('Default DS', {});
      _rasterizerState = _device.createRasterizerState('Default RS', {});
    }
    document.on.keyDown.add(_keyDownHandler);
    document.on.keyUp.add(_keyUpHandler);
    document.on.mouseMove.add(_mouseMoveHandler);
    document.on.mouseDown.add(_mouseDownHandler);
    document.on.mouseUp.add(_mouseUpHandler);
    _immediateContext.reset();
    return completer.future;
  }

  Future<JavelineDemoStatus> shutdown() {
    document.on.keyDown.remove(_keyDownHandler);
    document.on.keyUp.remove(_keyUpHandler);
    document.on.mouseMove.remove(_mouseMoveHandler);
    document.on.mouseDown.remove(_mouseDownHandler);
    document.on.mouseUp.remove(_mouseUpHandler);
    _device.deleteDeviceChild(_rasterizerState);
    _device.deleteDeviceChild(_depthState);
    _device.deleteDeviceChild(_blendState);
    _device.deleteDeviceChild(_viewPort);
    _quit = true;
    Completer<JavelineDemoStatus> completer = new Completer();
    JavelineDemoStatus status = new JavelineDemoStatus(JavelineDemoStatus.DemoStatusOKAY, 'Base OKAY');
    status.code = JavelineDemoStatus.DemoStatusOKAY;
    status.text = '';
    completer.complete(status);
    return completer.future;
  }

  void run() {
    window.requestAnimationFrame(_animationFrame);
  }

  bool get shouldQuit() => _quit;

  bool _animationFrame(num highResTime) {
    if (shouldQuit) {
      return false;
    }

    if (_time == 0 && _oldTime == 0) {
      // First time through
      _time = highResTime;
      _oldTime = highResTime;
      window.requestAnimationFrame(_animationFrame);
      return true;
    }

    _oldTime = _time;
    _time = highResTime;
    num dt = _time - _oldTime;
    _accumTime += dt;

    update(_accumTime/1000.0, dt/1000.0);

    window.requestAnimationFrame(_animationFrame);
    return true;
  }

  void drawGrid(int gridLines) {
    final int midLine = gridLines~/2;
    vec3 o = new vec3.zero();
    vec3 x = new vec3.raw(1.0, 0.0, 0.0);
    vec3 z = new vec3.raw(0.0, 0.0, 1.0);
    vec4 color = new vec4.raw(0.0, 1.0, 0.0, 1.0);

    for (int i = 0; i < gridLines; i++) {
      vec3 start = o + (z * (i-midLine)) + (x * -midLine);
      vec3 end = o + (z * (i-midLine)) + (x * midLine);
      debugDrawManager.addLine(start, end, color);
    }

    for (int i = 0; i < gridLines; i++) {
      vec3 start = o + (x * (i-midLine)) + (z * -midLine);
      vec3 end = o + (x * (i-midLine)) + (z * midLine);
      debugDrawManager.addLine(start, end, color);
    }
  }

  void update(num time, num dt) {
    _cameraController.forward = _keyboard.pressed(JavelineKeyCodes.KeyW);
    _cameraController.backward = _keyboard.pressed(JavelineKeyCodes.KeyS);
    _cameraController.strafeLeft = _keyboard.pressed(JavelineKeyCodes.KeyA);
    _cameraController.strafeRight = _keyboard.pressed(JavelineKeyCodes.KeyD);
    _cameraController.UpdateCamera(dt, _camera);
    JavelineConfigStorage.set('camera.lookAtPosition', _camera.lookAtPosition);
    JavelineConfigStorage.set('camera.eyePosition', _camera.eyePosition);
    {
      num yaw = _camera.yaw;
      num pitch = _camera.pitch;
      num deltaYaw = yaw - _lastYaw;
      num deltaPitch = pitch - _lastPitch;
      _lastYaw = yaw;
      _lastPitch = pitch;
      if (abs(deltaYaw) > 0.00001) {
        //spectreLog.Info('Camera Yaw: $deltaYaw');
      }
      if (abs(deltaPitch) > 0.00001) {
        //spectreLog.Info('Camera Pitch: $deltaPitch');
      }
    }
    device.gl.clearColor(0.0, 0.0, 0.0, 1.0);
    device.gl.clearDepth(1.0);
    device.gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT|WebGLRenderingContext.DEPTH_BUFFER_BIT);
    immediateContext.reset();
    immediateContext.setBlendState(_blendState);
    immediateContext.setRasterizerState(_rasterizerState);
    immediateContext.setDepthState(_depthState);
    immediateContext.setViewport(_viewPort);
    debugDrawManager.update(dt);
  }

  void keyboardEventHandler(KeyboardEvent event, bool down) {
    _keyboard.keyboardEvent(event, down);
  }

  void mouseMoveEventHandler(MouseEvent event) {
    _mouse.mouseMoveEvent(event);
    if (_mouse.pressed(JavelineMouseButtonCodes.MouseButtonLeft)) {
      _cameraController.accumDX += event.webkitMovementX;
      _cameraController.accumDY += event.webkitMovementY;
    }
  }

  void mouseButtonEventHandler(MouseEvent event, bool down) {
    _mouse.mouseButtonEvent(event, down);
  }

  void _keyDownHandler(KeyboardEvent event) {
    keyboardEventHandler(event, true);
  }

  void _keyUpHandler(KeyboardEvent event) {
    keyboardEventHandler(event, false);
  }

  void _mouseDownHandler(MouseEvent event) {
    mouseButtonEventHandler(event, true);
  }

  void _mouseUpHandler(MouseEvent event) {
    mouseButtonEventHandler(event, false);
  }

  void _mouseMoveHandler(MouseEvent event) {
    mouseMoveEventHandler(event);
  }
}