package deengames.abook.core;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxMath;
import flixel.util.FlxPoint;
import flixel.util.FlxColor;
import flixel.plugin.MouseEventManager;
import flixel.system.FlxSound;

import deengames.io.GestureManager;
import deengames.abook.FlurryWrapper;
import deengames.abook.GoogleAnalyticsWrapper;

/**
 * The below block is for animated GIFs (yagp)
import com.yagp.GifDecoder;
import com.yagp.Gif;
import com.yagp.GifPlayer;
import com.yagp.GifPlayerWrapper;
import com.yagp.GifRenderer;
import openfl.Assets;
*/

/**
* A common base state used for all scenes.
*/
class Screen extends FlxState
{
  public static var screens:Array<Class<Screen>> = new Array<Class<Screen>>();

  private var nextScreen:Screen;
  private var previousScreen:Screen;
  private var gestureManager:GestureManager = new GestureManager();
  private var audio:FlxSound;
  private var audioButton:FlxSprite;
  private var showAudioButton:Bool = true;
  private var sceneStart:Float = 0;

  /**
  * Function that is called up when to state is created to set it up.
  */
  override public function create():Void
  {
    this.gestureManager.onGesture(Gesture.Swipe, onSwipe);

    if (this.showAudioButton) {
      this.audioButton = this.addAndCenter('assets/images/play-sound.png');
      audioButton.x = FlxG.width - audioButton.width - 32;
      audioButton.y = FlxG.height - audioButton.height - 32;
      MouseEventManager.add(audioButton, null, clickedAudioButton);
    }

    var c:Class<Screen> = Type.getClass(this);

    var next = Screen.getnextScreen(c);
    if (next != null) {
      this.nextScreen = next;
    }

    var previous = Screen.getpreviousScreen(c);
    if (previous != null) {
      this.previousScreen = previous;
    }

    super.create();
    this.sceneStart = Date.now().getTime();
  }

  /**
  * Function that is called when this state is destroyed - you might want to
  * consider setting all objects this state uses to null to help garbage collection.
  */
  override public function destroy():Void
  {
    var sceneEnd:Float = Date.now().getTime();
    var elapsedSeconds = sceneEnd - this.sceneStart;
    // ms granularity on Android
    elapsedSeconds = Math.round(elapsedSeconds / 1000);
    FlurryWrapper.logEvent('Viewed Screen', {
      'Screen': getName(this), 'View Time (seconds)' : elapsedSeconds });

    super.destroy();
  }

  /**
  * Function that is called once every frame.
  */
  override public function update():Void
  {
    this.gestureManager.update();
    super.update();
  }

  // Used to start a new session. HaxeFlixel resumes on reopen.
  // Key duplicated in Main.main
  override public function onFocus() : Void
  {
    FlurryWrapper.startSession(Reg.flurryKey);
    GoogleAnalyticsWrapper.init(Reg.googleAnalyticsUrl);
    FlurryWrapper.logEvent('Resume', { 'Scene': getName(this) });
  }

  /**
   * Called on Mobile when the app loses focus / switches out
   * NOTE: this won't fire if FlxG.autoPause = true. The last
   * release that needed this is 3.3.6. If you upgrade, we're cool.
   * See: https://github.com/HaxeFlixel/flixel/issues/1408#issuecomment-67769018
   */
  override public function onFocusLost() : Void
  {
    FlurryWrapper.logEvent('Shutdown', { 'Final Screen': getName(this) });
    FlurryWrapper.endSession();
    super.onFocusLost();
  }

  private static function getnextScreen(currentType:Class<Screen>) : Screen
  {
    var arrayIndex = Screen.screens.indexOf(currentType);
    if (arrayIndex < Screen.screens.length - 1) {
      var c:Class<Screen> = Screen.screens[arrayIndex + 1];
      return Type.createInstance(c, []);
    } else {
      return null;
    }
  }

  private static function getpreviousScreen(currentType:Class<Screen>) : Screen
  {
    var arrayIndex = Screen.screens.indexOf(currentType);
    if (arrayIndex > 0) {
      var c:Class<Screen> = Screen.screens[arrayIndex - 1];
      return Type.createInstance(c, []);
    } else {
      return null;
    }
  }

  private function addAndCenter(fileName:String) : FlxSprite
  {
    var sprite = this.addSprite(fileName);
    centerOnScreen(sprite);
    return sprite;
  }

  private function addSprite(fileName:String) : FlxSprite
  {
    var sprite = new FlxSprite();
    sprite.loadGraphic(fileName);
    add(sprite);
    return sprite;
  }

  private function addAndCenterAnimation(spriteSheet:String, width:Int, height:Int, frames:Int, fps:Int) : FlxSprite
  {
    var sprite:FlxSprite = new FlxSprite();
    sprite.loadGraphic(spriteSheet, true, width, height);
    var range = [for (i in 0 ... frames) i];
    sprite.animation.add('loop', range, fps, true);
    sprite.animation.play('loop');
    add(sprite);
    centerOnScreen(sprite);
    return sprite;
  }

  // Requires YAGP
  /*
  private function addAndCenterAnimatedGif(file:String) : GifPlayerWrapper {
    var gif:Gif = GifDecoder.parseByteArray(Assets.getBytes(file));
    // Gif is null? Make sure in Project.xml, you specify *.gif as type=binary
    var player:GifPlayer = new GifPlayer(gif);
    var wrapper:GifPlayerWrapper = new GifPlayerWrapper(player);
    FlxG.addChildBelowMouse(wrapper);
    wrapper.x = (FlxG.width - wrapper.width) / 2;
    wrapper.y = (FlxG.height - wrapper.height) / 2;
    // wrapper.scaleX/scaleY
    return wrapper;
  }
  */

  private function scaleToFitNonUniform(sprite:FlxSprite) : Void
  {
    // scale to fit
    var scaleW = FlxG.width / sprite.width;
    var scaleH = FlxG.height / sprite.height;
    //  non-uniform scale
    sprite.scale.set(scaleW, scaleH);
  }

  private function scaleToFit(sprite:FlxSprite) : Void
  {
    var scaleW = FlxG.width / sprite.width;
    var scaleH = FlxG.height / sprite.height;
    var scale = Math.min(scaleW, scaleH);
    //  uniform scale
    sprite.scale.set(scale, scale);
  }

  private function centerOnScreen(sprite:FlxSprite) : Void
  {
    sprite.x = (FlxG.width - sprite.width) / 2;
    sprite.y = (FlxG.height - sprite.height) / 2;
  }

  private function onSwipe(direction:SwipeDirection) : Void
  {
    if (direction == SwipeDirection.Left && this.nextScreen != null) {
      //FlxG.camera.fade(FlxColor.BLACK, 0.5, false, shownextScreen);
      shownextScreen();
    } else if (direction == SwipeDirection.Right && this.previousScreen != null) {
      //FlxG.camera.fade(FlxColor.BLACK, 0.5, false, showpreviousScreen);
      showpreviousScreen();
    }
  }

  private function shownextScreen() : Void
  {
    logScene(this.nextScreen, 'Next');
    FlxG.switchState(this.nextScreen);
  }

  private function showpreviousScreen() : Void
  {
    logScene(this.previousScreen, 'Previous');
    FlxG.switchState(this.previousScreen);
  }

  private function logScene(s:Screen, direction:String) {
    FlurryWrapper.logEvent('ShowScreen', { 'Screen': getName(s), 'Direction': direction });
  }

  private function getName(s:Screen) : String {
    var name:String = (Type.getClassName(Type.getClass(s)));
    return name.substring(name.lastIndexOf('.') + 1, name.length);
  }

  // Called by clicking on button
  private function clickedAudioButton(sprite:FlxSprite) : Void {
    playAudio();
  }

  // Called from subclass scenes
  private function loadAndPlay(file:String) : Void
  {
    if (this.audio != null) {
      this.audio.stop();
    }

    this.audio = FlxG.sound.load(file + deengames.io.AudioManager.SOUND_EXT);
    this.playAudio();
  }

  // Called in scenes
  private function playAudio() : Void {
    if (this.audio != null) {
      this.audio.stop();
      this.audio.play(true); // force restart
    }
  }

  private function hideAudioButton() : Void
  {
    this.showAudioButton = false; // if constructor wasn't called yet
    if (this.audioButton != null) {
      this.audioButton.destroy();
    }
  }
}