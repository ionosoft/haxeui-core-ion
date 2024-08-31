package haxe.ui.components;

import haxe.ui.Toolkit;
import haxe.ui.actions.ActionType;
import haxe.ui.behaviours.Behaviour;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.behaviours.DefaultBehaviour;
import haxe.ui.core.Component;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.core.ICompositeInteractiveComponent;
import haxe.ui.core.IDirectionalComponent;
import haxe.ui.core.InteractiveComponent;
import haxe.ui.core.Screen;
import haxe.ui.events.ActionEvent;
import haxe.ui.events.DragEvent;
import haxe.ui.events.Events;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Point;
import haxe.ui.util.MathUtil;
import haxe.ui.util.Variant;

/**
 * A slider component, containing a thumb and a track to move the thumb along.
 */
@:composite(SliderBuilder)
class Slider extends InteractiveComponent implements IDirectionalComponent implements ICompositeInteractiveComponent {
    
    /**
     * Creates a new Slider.
     */
    private function new() {
        super();
        cascadeActive = true;
        actionRepeatInterval = 160;
    }

    //***********************************************************************************************************
    // Public API
    //***********************************************************************************************************

    /**
    * Utility property to add a single `DragEvent.DRAG_START` event
    */
    @:event(DragEvent.DRAG_START)                   public var onDragStart:DragEvent->Void;    

    /**
    * Utility property to add a single `DragEvent.DRAG` event
    */
    @:event(DragEvent.DRAG)                         public var onDrag:DragEvent->Void;    

    /**
    * Utility property to add a single `DragEvent.DRAG_END` event
    */
    @:event(DragEvent.DRAG_END)                     public var onDragEnd:DragEvent->Void;    

    /**
     * The minimum value of the slider. used to calculate the thumb's position.
     */
    @:clonable @:behaviour(MinBehaviour, 0)         public var min:Float;

    /**
     * The maximum value of the slider. used to calculate the thumb's position.
     */
    @:clonable @:behaviour(MaxBehaviour, 100)       public var max:Float;

    /**
     * How many numbers after the decimal points are calculated for the position of the thumb.
     */
    @:clonable @:behaviour(DefaultBehaviour, null)  public var precision:Null<Int>;

    /**
     * The value the fill of the slider starts from.
     * 
     * When `end` is defined, another moveable thumb will appear at the position `start`.
     */
    @:clonable @:behaviour(StartBehaviour, null)    public var start:Null<Float>;

    /**
     * The value the fill of the slider ends at.
     * 
     * When `start` is defined, another moveable thumb will appear at the position `end`.
     */
    @:clonable @:behaviour(EndBehaviour, 0)         public var end:Float;

    /**
     * The value the thumb is currently at.
     */
    @:clonable @:behaviour(PosBehaviour)            public var pos:Float;

    /**
     * When defined & two thumbs are present, provides an offset to the actual center:
     * 
     * the leftmost thumb will always be before the center, and the rightmost thumb will always be after the center.
     */
    @:clonable @:behaviour(CenterBehaviour, null)   public var center:Null<Float>;

    /**
     * When defined, snaps the thumb to the nearest step, example:
     * 
     * if pos is 6 and step is 10, the thumb will be moved to 10.
     */
    @:clonable @:behaviour(DefaultBehaviour, null)  public var step:Null<Float>;

    /**
     * When defined, creates little ticks each time a value divisible by `minorTicks` is reached. 
     * 
     * in horizontal sliders, by default, the ticks apper below slider
     */
    @:clonable @:behaviour(MinorTicks, null)        public var minorTicks:Null<Float>;

    /**
     * When defined, creates ticks each time a value divisible by `majorTicks` is reached. 
     * 
     * in horizontal sliders, by default, the ticks apper below slider
     */
    @:clonable @:behaviour(MajorTicks, null)        public var majorTicks:Null<Float>;

    /**
     * The current value of the slider.
     *
     * `value` is a universal way to access the "core" value a component is based on.
     * In this case, value represents the current position of the thumb inside the slider.
     */
    @:clonable @:value(pos)                         public var value:Dynamic;

    //***********************************************************************************************************
    // Private API
    //***********************************************************************************************************
    @:call(PosFromCoord)                            private function posFromCoord(coord:Point):Float;
}

//***********************************************************************************************************
// Behaviours
//***********************************************************************************************************
@:dox(hide) @:noCompletion
@:access(haxe.ui.components.Slider)
@:access(haxe.ui.core.Component)
private class StartBehaviour extends DataBehaviour {
    private override function validateData() {
        if (_value == null || _value.isNull) {
            return;
        }

        if (_value.isNaN) {
            return;
        }

        var builder:SliderBuilder = cast(_component._compositeBuilder, SliderBuilder);
        if (_component.findComponent("start-thumb") == null) {
            builder.createThumb("start-thumb");
        }

        var slider:Slider = cast(_component, Slider);
        if (_value != null && _value < slider.min) {
            _value = slider.min;
        }

        if (_value != null && _value > slider.max) {
            _value = slider.max;
        }

        if (slider.precision != null) {
            _value = MathUtil.round(_value, slider.precision);
        }

        if (slider.step != null) {
            _value = MathUtil.roundToNearest(_value, slider.step);
        }
        
        _component.findComponent(Range).start = _value;
        _component.invalidateComponentLayout();
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.components.Slider)
@:access(haxe.ui.components.Range)
private class EndBehaviour extends DataBehaviour {
    private override function validateData() {
        if (_value == null || _value.isNull) {
            return;
        }

        if (_value.isNaN) {
            return;
        }

        var range = _component.findComponent(Range);
        if (range == null) {
            return;
        }
        
        var slider:Slider = cast(_component, Slider);
        if (_value != null && _value < slider.min) {
            _value = slider.min;
        }

        if (_value != null && _value > slider.max) {
            _value = slider.max;
        }

        if (slider.precision != null) {
            _value = MathUtil.round(_value, slider.precision);
        }

        if (slider.step != null) {
            _value = MathUtil.roundToNearest(_value, slider.step);
        }
        
        if (slider.center != null) {
            if (_value >= slider.center) {
                range.virtualStart = slider.center;
                range.virtualEnd = _value;
            } else if (_value < slider.center) {
                range.virtualStart = _value;
                range.virtualEnd = slider.center;
            }
        }
        
        range.end = _value;
        cast(_component, Slider).pos = _value;
        _component.invalidateComponentLayout();
    }
}

@:dox(hide) @:noCompletion
private class MinBehaviour extends DataBehaviour {
    private override function validateData() {
        if (_value == null || _value.isNull) {
            return;
        }

        if (_value.isNaN) {
            return;
        }

        var range = _component.findComponent(Range);
        if (range == null) {
            return;
        }
        var slider = cast(_component, Slider);
        if (slider.start == null) {
            range.start = _value;
        }
        range.min = _value;
        if (slider.minorTicks != null) {
            --slider.minorTicks;
            ++slider.minorTicks;
        }
        if (slider.majorTicks != null) {
            --slider.majorTicks;
            ++slider.majorTicks;
        }
        _component.invalidateComponentLayout();
    }
}

@:dox(hide) @:noCompletion
private class MaxBehaviour extends DataBehaviour {
    private override function validateData() {
        if (_value == null || _value.isNull) {
            return;
        }

        if (_value.isNaN) {
            return;
        }

        var range = _component.findComponent(Range);
        if (range == null) {
            return;
        }
        var slider = cast(_component, Slider);
        range.max = _value;
        if (slider.minorTicks != null) {
            --slider.minorTicks;
            ++slider.minorTicks;
        }
        if (slider.majorTicks != null) {
            --slider.majorTicks;
            ++slider.majorTicks;
        }
        _component.invalidateComponentLayout();
    }
}

@:dox(hide) @:noCompletion
private class PosBehaviour extends DataBehaviour {
    /*
    public override function get():Variant {
        if (_component.isReady == false) {
            return _value;
        }
        return cast(_component, Slider).end;
    }
    */

    public override function set(value:Variant) {
        if (_component.isReady == false) {
            _value = value;
            cast(_component, Slider).end = _value;
            invalidateData();
            return;
        }

        super.set(value);
    }

    private override function validateData() {
        cast(_component, Slider).end = _value;
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.components.Range)
private class CenterBehaviour extends DefaultBehaviour {
    public override function set(value:Variant) {
        super.set(value);
        if (_value.isNaN) {
            return;
        }

        if (value != null && value.isNull == false) {
            var slider:Slider = cast(_component, Slider);
            slider.pos = _value;
            var v = _component.findComponent(Range);
            if (v != null) {
                v.virtualStart = _value;
            }
            
            _component.addClass("with-center");
        } else {
            _component.removeClass("with-center");
        }
    }
}

private class MinorTicks extends DataBehaviour {
    public override function validateData() {
        if (_value.isNaN) {
            return;
        }

        if (_value != null && _value.isNull == false) {
            var slider:Slider = cast(_component, Slider);
            slider.addClass("minor-ticks");
            var ticks = slider.findComponents("minor-tick", 1);
            var v:Float = _value;
            var m:Float = slider.max - slider.min;
            var n:Int = Std.int(m / v) + 1;
            if (ticks == null || ticks.length != n) {
                var index = slider.getComponentIndex(slider.findComponent(Range));
                var addN = Std.int(n - ticks.length);
                for (_ in 0...addN) {
                    var tick = new Component();
                    tick.addClass("minor-tick");
                    tick.scriptAccess = false;
                    slider.addComponent(tick);
                    slider.setComponentIndex(tick, index + 1);
                }
                var removeN = Std.int(ticks.length - n);
                for (_ in 0...removeN) {
                    slider.removeComponentAt(index + 1);
                }
            }
        } else {
            _component.removeClass("minor-ticks");
        }
    }
}

private class MajorTicks extends DataBehaviour {
    public override function validateData() {
        if (_value.isNaN) {
            return;
        }

        if (_value != null && _value.isNull == false) {
            var slider:Slider = cast(_component, Slider);
            slider.addClass("major-ticks");
            var ticks = slider.findComponents("major-tick", 1);
            var v:Float = _value;
            var m:Float = slider.max - slider.min;
            var n:Int = Std.int(m / v) + 1;
            if (ticks == null || ticks.length != n) {
                var index = slider.getComponentIndex(slider.findComponent(Range));
                var addN = Std.int(n - ticks.length);
                for (_ in 0...addN) {
                    var tick = new Component();
                    tick.addClass("major-tick");
                    tick.scriptAccess = false;
                    slider.addComponent(tick);
                    slider.setComponentIndex(tick, index + 1);
                }
                var removeN = Std.int(ticks.length - n);
                for (_ in 0...removeN) {
                    slider.removeComponentAt(index + 1);
                }
            }
        } else {
            _component.removeClass("major-ticks");
        }
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.components.Range)
private class PosFromCoord extends Behaviour {
    public override function call(coord:Any = null):Variant {
        var range:Range = _component.findComponent(Range);
        return range.posFromCoord(coord);
    }
}

//***********************************************************************************************************
// Events
//***********************************************************************************************************
@:dox(hide) @:noCompletion
@:access(haxe.ui.components.Slider)
private class Events extends haxe.ui.events.Events  {
    private var _slider:Slider;

    private var _endThumb:Button;
    private var _startThumb:Button;
    private var _range:Range;

    private var _activeThumb:Button;

    public function new(slider:Slider) {
        super(slider);
        _slider = slider;
        _range = slider.findComponent(Range);
    }

    public override function register() {
        _startThumb = _slider.findComponent("start-thumb");
        if (_startThumb != null && _startThumb.hasEvent(MouseEvent.MOUSE_DOWN, onThumbMouseDown) == false) {
            _startThumb.registerEvent(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        }

        _endThumb = _slider.findComponent("end-thumb");
        if (_endThumb != null && _endThumb.hasEvent(MouseEvent.MOUSE_DOWN, onThumbMouseDown) == false) {
            _endThumb.registerEvent(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        }

        if (_range != null && _range.hasEvent(MouseEvent.MOUSE_DOWN, onRangeMouseDown) == false) {
            _range.registerEvent(MouseEvent.MOUSE_DOWN, onRangeMouseDown);
        }
        if (_range != null && _range.hasEvent(UIEvent.CHANGE, onRangeChange) == false) {
            _range.registerEvent(UIEvent.CHANGE, onRangeChange);
        }
        if (hasEvent(ActionEvent.ACTION_START, onActionStart) == false) {
            registerEvent(ActionEvent.ACTION_START, onActionStart);
        }
        if (hasEvent(ActionEvent.ACTION_END, onActionEnd) == false) {
            registerEvent(ActionEvent.ACTION_END, onActionEnd);
        }
    }

    public override function unregister() {
        if (_startThumb != null) {
            _startThumb.unregisterEvent(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        }

        if (_endThumb != null) {
            _endThumb.unregisterEvent(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        }

        if (_range != null) {
            _range.unregisterEvent(MouseEvent.MOUSE_DOWN, onRangeMouseDown);
            _range.unregisterEvent(UIEvent.CHANGE, onRangeChange);
        }
        unregisterEvent(ActionEvent.ACTION_START, onActionStart);
        unregisterEvent(ActionEvent.ACTION_START, onActionEnd);
    }

    private var _rangeSynced:Bool = false;
    private function onRangeChange(e:UIEvent) {
        if (_rangeSynced == false && _range.end == _slider.end) {
            _rangeSynced = true;
            if (_slider.end == 0) {
                return;
            }
        }
        if (_rangeSynced == false) {
            return;
        }
        var event = new UIEvent(UIEvent.CHANGE);
        event.previousValue = e.previousValue;
        event.value = e.value;
        _slider.dispatch(event);
        if (_activeThumb != null) {
            var dragEvent = new DragEvent(DragEvent.DRAG);
            dragEvent.previousValue = e.previousValue;
            dragEvent.value = e.value;
            _slider.dispatch(dragEvent);
        }
    }

    private function onRangeMouseDown(e:MouseEvent) {
        if (_startThumb != null && _startThumb.hitTest(e.screenX, e.screenY) == true) {
            return;
        }
        if (_endThumb != null && _endThumb.hitTest(e.screenX, e.screenY) == true) {
            return;
        }

        _slider.focus = true;
        
        e.screenX *= Toolkit.scaleX;
        e.screenY *= Toolkit.scaleY;
        e.cancel();

        var coord:Point = new Point();
        coord.x = (e.screenX - _slider.screenLeft) - _slider.paddingLeft * Toolkit.scaleX;
        coord.y = (e.screenY - _slider.screenTop) - _slider.paddingTop * Toolkit.scaleY;
        var pos:Float = _slider.posFromCoord(coord);

        if (_startThumb == null) {
            _slider.pos = pos;
            startDrag(_endThumb, (_endThumb.actualComponentWidth / 2), (_endThumb.actualComponentHeight / 2));
            return;
        }

        var builder:SliderBuilder = cast(_slider._compositeBuilder, SliderBuilder);
        var d1 = _slider.end - _slider.start;
        var d2 = pos - _slider.start;
        if (d2 < d1 / 2) {
            pos -= builder.getStartOffset();
            _slider.start = pos;
            startDrag(_startThumb, (_startThumb.actualComponentWidth / 2), (_startThumb.actualComponentHeight / 2));
        } else if (d2 >= d1 / 2) {
            pos -= builder.getStartOffset();
            _slider.end = pos;
            startDrag(_endThumb, (_endThumb.actualComponentWidth / 2), (_endThumb.actualComponentHeight / 2));
        } else if (pos > _slider.start) {
            _slider.end = pos;
            startDrag(_endThumb, (_endThumb.actualComponentWidth / 2), (_endThumb.actualComponentHeight / 2));
        } else if (pos < _slider.end) {
            _slider.start = pos;
            startDrag(_startThumb, (_startThumb.actualComponentWidth / 2), (_startThumb.actualComponentHeight / 2));
        }
    }

    private var _offset:Point = null;
    private function onThumbMouseDown(e:MouseEvent) {
        e.cancel();
        _slider.focus = true;
        startDrag(cast(e.target, Button), e.localX * Toolkit.scaleX, e.localY * Toolkit.scaleX);
    }

    private function startDrag(thumb:Button, offsetX:Float, offsetY:Float) {
        _offset = new Point(offsetX, offsetY);
        _activeThumb = thumb;
        Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onScreenMouseMove);
        Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onScreenMouseUp);
        
        _slider.dispatch(new DragEvent(DragEvent.DRAG_START));
    }

    private function onScreenMouseUp(e:MouseEvent) {
        _activeThumb = null;
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onScreenMouseUp);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onScreenMouseMove);
        
        _slider.dispatch(new DragEvent(DragEvent.DRAG_END));
    }

    private function onScreenMouseMove(e:MouseEvent) {
        e.screenX *= Toolkit.scaleX;
        e.screenY *= Toolkit.scaleY;
        var coord:Point = new Point();
        coord.x = (e.screenX - _slider.screenLeft - _offset.x) - (_slider.paddingLeft * Toolkit.scaleX) +  (_activeThumb.actualComponentWidth / 2);
        coord.y = (e.screenY - _slider.screenTop - _offset.y) - (_slider.paddingTop * Toolkit.scaleX) +  (_activeThumb.actualComponentHeight / 2);
        var pos:Float = _slider.posFromCoord(coord);

        var builder:SliderBuilder = cast(_slider._compositeBuilder, SliderBuilder);
        if (_activeThumb == _startThumb) {
            pos -= builder.getStartOffset();
            if (pos > _slider.end) {
                pos = _slider.end;
            }
            _slider.start = pos;
        } else if (_activeThumb == _endThumb) {
            pos -= builder.getStartOffset();
            _slider.end = pos;
        }
    }

    var repeats:Int = 0;    
    private function onActionStart(event:ActionEvent) {    
        var diff = 1.;
        switch (event.action) {
            case ActionType.RIGHT | ActionType.UP:
            case ActionType.LEFT | ActionType.DOWN:
                diff = -1;
            case _:
                return;
        }
        repeats++;
        event.repeater = true;

        var step = 1.;
        if (_slider.step != null) {
            step = _slider.step;
        }
        var speed = step * repeats * repeats * repeats;
        var maxSpeed = MathUtil.roundToNearest((_slider.max - _slider.min)/ 6, step) ;
        if (speed > maxSpeed ) speed = maxSpeed;
        _slider.value += (diff * speed);
        if (_slider.step == null) {
            _slider.value = Math.round(_slider.value);
        }
    }

    private function onActionEnd(event:ActionEvent) {    
        switch (event.action) {
            case ActionType.RIGHT | ActionType.UP | ActionType.LEFT | ActionType.DOWN:
                repeats = 0;
            case _:    
        }
    }
}

//***********************************************************************************************************
// Composite Builder
//***********************************************************************************************************
@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
class SliderBuilder extends CompositeBuilder {
    private var _slider:Slider;
    
    public function new(slider:Slider) {
        super(slider);
        _slider = slider;
        showWarning();
    }
    
    public override function create() {
        if (_component.findComponent("range") == null) {
            var v = createValueComponent();
            if (v != null) {
                v.scriptAccess = false;
                v.allowFocus = false;
                v.id = "range";
                v.addClass("slider-value");
                v.start = v.end = 0;
                if (_slider.center != null) {
                    _slider.pos = _slider.center;
                    v.virtualStart = _slider.center;
                }
                _component.addComponent(v);
            }
        }

        createThumb("end-thumb");
    }
    
    public function getStartOffset():Float {
        return 0;
    }

    private function createValueComponent():Range {
        return null;
    }

    public function createThumb(id:String) {
        if (_component.findComponent(id) != null) {
            return;
        }

        var b = new Button();
        b.scriptAccess = false;
        b.allowFocus = false;
        b.id = id;
        b.addClass(id);
        b.remainPressed = true;
        _component.addComponent(b);

        _component.registerInternalEvents(Events, true); // call .register again as we might have a new thumb!
    }
    
    private function showWarning() {
        trace("WARNING: trying to create an instance of 'Slider' directly, use either 'HorizontalSlider' or 'VerticalSlider'");
    }
}
