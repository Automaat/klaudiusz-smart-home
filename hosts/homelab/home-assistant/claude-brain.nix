{ config, lib, ... }:

{
  services.home-assistant.config = {

    # ===========================================
    # Input Helpers - Claude State Management
    # ===========================================
    input_text = {
      claude_session = {
        name = "Claude Session ID";
        max = 100;
        initial = "";
      };
      claude_response = {
        name = "Claude Last Response";
        max = 500;
        initial = "";
      };
      claude_pending_action = {
        name = "Claude Pending Action Description";
        max = 500;
        initial = "";
      };
    };

    input_boolean.claude_awaiting_confirmation = {
      name = "Claude Awaiting Confirmation";
      initial = false;
    };

    # ===========================================
    # Claude Brain Component
    # ===========================================
    claude_brain = {};

    # ===========================================
    # Command Line Sensor - Server Health
    # ===========================================
    command_line = [
      {
        sensor = {
          name = "Claude Server Status";
          unique_id = "claude_server_status";
          command = "timeout 5 curl -s --max-time 3 http://192.168.0.34:8742/health | jq -r '.status // \"offline\"'";
          scan_interval = 60;
        };
      }
    ];

    # ===========================================
    # Template Sensors - Conversation State
    # ===========================================
    template = [
      {
        sensor = [
          {
            name = "Claude Conversation State";
            unique_id = "claude_conversation_state";
            state = ''
              {% if is_state('input_boolean.claude_awaiting_confirmation', 'on') %}
                awaiting_confirmation
              {% elif states('input_text.claude_session') != '''' %}
                active_session
              {% else %}
                idle
              {% endif %}
            '';
            attributes = {
              session_id = "{{ states('input_text.claude_session') }}";
              last_response = "{{ states('input_text.claude_response') }}";
              pending_action = "{{ states('input_text.claude_pending_action') }}";
              server_status = "{{ states('sensor.claude_server_status') }}";
            };
          }
        ];
      }
    ];

    # ===========================================
    # Monitoring Automation - Server Health Alerts
    # ===========================================
    automation = [
      {
        id = "claude_server_offline_alert";
        alias = "Alert - Claude server offline";
        trigger = [
          {
            platform = "state";
            entity_id = "sensor.claude_server_status";
            to = "offline";
            for = "00:02:00";
          }
        ];
        action = [
          {
            action = "persistent_notification.create";
            data = {
              title = "Claude Server Offline";
              message = "Claude HA Brain server at 192.168.0.34:8742 is unreachable. Check Mac server.";
            };
          }
        ];
      }
    ];
  };
}
