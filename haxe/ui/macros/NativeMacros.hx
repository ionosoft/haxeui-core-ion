package haxe.ui.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.ui.macros.helpers.CodeBuilder;
import haxe.ui.parsers.config.ConfigParser;
import haxe.ui.util.GenericConfig;
import sys.io.File;
#end

class NativeMacros {
    private static var _nativeProcessed:Bool;

    macro public static function processNative():Expr {
        #if !haxeui_experimental_no_cache
        if (_nativeProcessed == true) {
            return macro null;
        }
        #end

        _nativeProcessed = true;

        var nativeConfigs:Array<GenericConfig> = loadNativeConfig();
        var builder = new CodeBuilder();
        for (config in nativeConfigs) {
            MacroHelpers.buildGenericConfigCode(builder, config, "nativeConfig");
        }

        return builder.expr;
    }

    #if macro
    private static var _nativeConfigLoaded:Bool = false;
    private static var _nativeConfigs:Array<GenericConfig> = new Array<GenericConfig>();
    public static function loadNativeConfig():Array<GenericConfig> {
        #if !haxeui_experimental_no_cache
        if (_nativeConfigLoaded == true) {
            return _nativeConfigs;
        }
        #end

        #if haxeui_macro_times
        var stopTimer = Context.timer("NativeMacros.loadNativeConfig");
        #end
        MacroHelpers.scanClassPath(function(filePath:String, base:String) {
            var parser:ConfigParser = ConfigParser.get(MacroHelpers.extension(filePath));
            if (parser != null) {
                try {
                    var config:GenericConfig = parser.parse(File.getContent(filePath), Context.getDefines());
                    _nativeConfigs.push(config);
                    return true;
                } catch (e:Dynamic) {
                    trace('WARNING: Problem parsing native ${MacroHelpers.extension(filePath)} (${filePath}) - ${e} (skipping file)');
                    return false;
                }
            }

            return false;
        }, ["native."]);
        #if haxeui_macro_times
        stopTimer();
        #end

        _nativeConfigLoaded = true;
        return _nativeConfigs;
    }
    #end
}