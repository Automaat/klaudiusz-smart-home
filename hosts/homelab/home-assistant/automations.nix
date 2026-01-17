{
  config,
  pkgs,
  lib,
  ...
}: let
  # ===========================================
  # Import Area-Specific Automations
  # ===========================================
  systemAutomations = import ./areas/system.nix {inherit config pkgs lib;};
  kitchenAutomations = import ./areas/kitchen.nix {inherit config pkgs lib;};
  bathroomAutomations = import ./areas/bathroom.nix {inherit config pkgs lib;};
  bedroomAutomations = import ./areas/bedroom.nix {inherit config pkgs lib;};
  livingRoomAutomations = import ./areas/living-room.nix {inherit config pkgs lib;};
  hallwayAutomations = import ./areas/hallway.nix {inherit config pkgs lib;};
  officeAutomations = import ./areas/office.nix {inherit config pkgs lib;};
  garderobaAutomations = import ./areas/garderoba.nix {inherit config pkgs lib;};
  analyticsAutomations = import ./areas/analytics.nix {inherit config pkgs lib;};

  # ===========================================
  # Import Other Components
  # ===========================================
  sensors = import ./sensors.nix {inherit config pkgs lib;};
  helpers = import ./helpers.nix {inherit config pkgs lib;};
  scripts = import ./scripts.nix {inherit config pkgs lib;};
in {
  services.home-assistant.config = {
    # ===========================================
    # Automations (aggregated from all areas)
    # ===========================================
    automation =
      systemAutomations.automation
      ++ kitchenAutomations.automation
      ++ bathroomAutomations.automation
      ++ bedroomAutomations.automation
      ++ livingRoomAutomations.automation
      ++ hallwayAutomations.automation
      ++ officeAutomations.automation
      ++ garderobaAutomations.automation
      ++ analyticsAutomations.automation;

    # ===========================================
    # Template Sensors
    # ===========================================
    template = sensors.template;

    # ===========================================
    # Input Helpers
    # ===========================================
    input_boolean = helpers.input_boolean;
    input_datetime = helpers.input_datetime;
    input_number = helpers.input_number;

    # ===========================================
    # Scripts
    # ===========================================
    script = scripts.script;
  };
}
