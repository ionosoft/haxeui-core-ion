package haxe.ui.backend;

import haxe.ui.Toolkit;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.validation.InvalidationFlags;

class ScreenBase {
    public var rootComponents:Array<Component> = [];

    private var _options:ToolkitOptions;
    public var options(get, set):ToolkitOptions;
    private function get_options():ToolkitOptions {
        return _options;
    }
    private function set_options(value:ToolkitOptions):ToolkitOptions {
        _options = value;
        return value;
    }

    public var dpi(get, null):Float;
    private function get_dpi():Float {
        return 72;
    }

    public var title(get, set):String;
    private function get_title():String {
        return null;
    }
    private function set_title(s:String):String {
        return s;
    }

    public var width(get, null):Float;
    private function get_width():Float {
        return 0;
    }

    public var height(get, null):Float;
    private function get_height():Float {
        return 0;
    }

    public var actualWidth(get, null):Float;
    private function get_actualWidth():Float {
        return width * Toolkit.scaleX;
    }

    public var actualHeight(get, null):Float;
    private function get_actualHeight():Float {
        return height * Toolkit.scaleY;
    }
    
    public var isRetina(get, null):Bool;
    private function get_isRetina():Bool {
        return false;
    }

    public var topComponent(get, null):Component;
    private function get_topComponent():Component {
        if (rootComponents.length == 0) {
            return null;
        }

        // lets make a little "hack": if the "top" component has
        // 'pointer-events:none' lets assume that it shouldnt
        // be considered "top" 
        var n = rootComponents.length - 1;
        var c = null;
        while (n >= 0) {
            c = rootComponents[n];
            if (c.style == null) {
                break;
            }
            if (c.style.pointerEvents != "none") {
                break;
            }
            n--;
        }
        return c;
    }
    
    public function addComponent(component:Component):Component {
        return component;
    }

    public function removeComponent(component:Component, dispose:Bool = true):Component {
        return component;
    }

    private function handleSetComponentIndex(child:Component, index:Int) {
    }

    private function resizeComponent(c:Component) {
        var cx:Null<Float> = null;
        var cy:Null<Float> = null;

        if (c.percentWidth > 0) {
            cx = (this.width * c.percentWidth) / 100;
        }
        if (c.percentHeight > 0) {
            cy = (this.height * c.percentHeight) / 100;
        }
        c.resizeComponent(cx, cy);
    }

    public function refreshStyleRootComponents() {
        for (component in rootComponents) {
            _refreshStyleComponent(component);
        }
    }

    public function resizeRootComponents() {
        for (component in rootComponents) {
            resizeComponent(component);
        }
    }

    @:access(haxe.ui.core.Component)
    private function _refreshStyleComponent(component:Component) {
        for (child in component.childComponents) {
//            child.applyStyle(child.style);
            child.invalidateComponentStyle();
            child.invalidateComponentDisplay();
            _refreshStyleComponent(child);
        }
    }

    private function _onRootComponentResize(e:UIEvent) {
        _refreshStyleComponent(e.target);
    }

    public function invalidateAll(flag:String = InvalidationFlags.ALL) {
        for (c in rootComponents) {
            invalidateChildren(c, flag);
        }
    }

    private function invalidateChildren(c:Component, flag:String = InvalidationFlags.ALL) {
        for (child in c.childComponents) {
            invalidateChildren(child, flag);
        }
        c.invalidateComponent(flag);
    }

    //***********************************************************************************************************
    // Events
    //***********************************************************************************************************
    private function supportsEvent(type:String):Bool {
        return false;
    }

    private function mapEvent(type:String, listener:UIEvent->Void) {
    }

    private function unmapEvent(type:String, listener:UIEvent->Void) {
    }
}