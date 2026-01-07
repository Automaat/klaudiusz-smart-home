{
  config,
  pkgs,
  lib,
  ...
}: {
  # ===========================================
  # System & Task Management
  # ===========================================
  automation = [
    # -----------------------------------------
    # Startup
    # -----------------------------------------
    {
      id = "startup_notification";
      alias = "System - Startup notification";
      trigger = [
        {
          platform = "homeassistant";
          event = "start";
        }
      ];
      action = [
        {
          service = "persistent_notification.create";
          data = {
            title = "Home Assistant";
            message = "System started at {{ now().strftime('%H:%M') }}";
          };
        }
        # {
        #   action = "notify.send_message";
        #   target.entity_id = "notify.klaudiusz_smart_home_system";
        #   data = {
        #     message = "✅ Home Assistant started at {{ now().strftime('%H:%M') }}";
        #   };
        # }
      ];
    }

    # -----------------------------------------
    # Task Management (Todoist)
    # -----------------------------------------
    {
      id = "todoist_task_added_confirmation";
      alias = "Todoist - Task added confirmation";
      trigger = [
        {
          platform = "state";
          entity_id = "todo.inbox";
        }
      ];
      condition = [
        {
          condition = "template";
          value_template = "{{ trigger.to_state.state | int > trigger.from_state.state | int }}";
        }
      ];
      action = [
        {
          service = "tts.speak";
          target.entity_id = "tts.piper";
          data = {
            message = "Zadanie dodane do listy";
          };
        }
      ];
    }
  ];
}
