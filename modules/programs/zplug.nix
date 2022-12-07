{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.zplug;

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The plugin tags.";
      };
    };

  });

in {
  options.programs.zsh.zplug = {
    enable = mkEnableOption "zplug - a zsh plugin manager";

    package = mkOption {
      type = types.package;
      default = pkgs.zplug;
      defaultText = literalExpression "pkgs.zplug";
      description = "zplug package to install.";
    };

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = "List of zplug plugins.";
    };

    zplugHome = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.zplug";
      defaultText = "~/.zplug";
      apply = toString;
      description = "Path to zplug home directory.";
    };

    zplugInitScriptPath = mkOption {
      type = types.path;
      default = "${cfg.package}/init.zsh";
      defaultText = "<package>/init.zsh";
      description = "Path to zplug init.zsh";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.zsh.initExtraBeforeCompInit = ''
      export ZPLUG_HOME=${cfg.zplugHome}

      source ${cfg.zplugInitScriptPath}

      ${optionalString (cfg.plugins != [ ]) ''
        ${concatStrings (map (plugin: ''
          zplug "${plugin.name}"${
            optionalString (plugin.tags != [ ]) ''
              ${concatStrings (map (tag: ", ${tag}") plugin.tags)}
            ''
          }
        '') cfg.plugins)}
      ''}

      if ! zplug check; then
        zplug install
      fi

      zplug load
    '';

  };
}
