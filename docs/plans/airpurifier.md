# Air Purifier Automation Plan - Xiaomi Air Purifier 3H

## Progress Summary

| Phase | Status | PR | Description |
| ------- | -------- | ---- | ---- |
| Phase 1 | ✅ | #189 | Template sensors (PM2.5, filter urgency, ventilation safety) |
| Phase 2 | ✅ | #189 | Input helpers (away mode, antibacterial tracking) |
| Phase 3 | ✅ | #192 | Core automations (9 total) |
| Phase 4 | 🔄 | - | Polish voice commands - in PR |
| Phase 5 | ✅ | - | Component config (already done) |

## Current State

### ✅ Setup Complete

- Xiaomi Home integration configured (OAuth)
- Device: `fan.zhimi_de_334622045_mb3_s_2_air_purifier`
- Location: Living Room (Salon)
- GIOS outdoor AQ integration: `sensor.aleje_pm2_5` (Kraków)
- Todoist integration: Available for task management

### ⚠️ Critical Issues

- **Filter at 15% life** (2966h used) - replacement urgent

### 📊 Current Readings

- **Indoor PM2.5**: 10 µg/m³ (excellent, WHO target <5)
- **Outdoor PM2.5**: 50.8 µg/m³ (moderate)
- **Humidity**: 44%
- **Purifier status**: Off

## Goals

1. **Outdoor-driven automation** - React to external AQ changes
2. **Indoor quality maintenance** - Keep PM2.5 <5 µg/m³
3. **Sleep mode adaptation** - Auto if PM2.5 >75, else Night mode
4. **Filter tracking** - Todoist tasks for replacement
5. **Antibacterial automation** - Periodic high-power runs (not just reminders)
6. **Energy efficiency** - Smart operation during away mode
7. **Voice control** - Polish commands for manual override

## Architecture: Modular Multi-Room Pattern

**Design for future expansion:**

- Reusable template sensors (parameterized by entity_id)
- Shared helper: `input_boolean.high_pollution_mode`
- Room-agnostic automation templates
- Device-specific overrides via conditions

## Implementation Plan

### Phase 1: Template Sensors ✅

**File**: `hosts/homelab/home-assistant/automations.nix`

**Add 5 template sensors (modern format):**

1. **PM2.5 Outdoor vs Indoor Differential**

   ```nix
   {
     sensor = [{
       name = "PM2.5 Outdoor vs Indoor (Living Room)";
       unique_id = "pm25_outdoor_indoor_diff_living_room";
       state = "{{ states('sensor.aleje_pm2_5') | float(0) - states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(0) }}";
       unit_of_measurement = "µg/m³";
       device_class = "pm25";
     }];
   }
   ```

2. **Air Purifier Recommended Mode**

   ```nix
   {
     sensor = [{
       name = "Air Purifier Recommended Mode";
       unique_id = "air_purifier_recommended_mode";
       state = ''
         {% set outdoor = states('sensor.aleje_pm2_5') | float(0) %}
         {% set indoor = states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(0) %}
         {% if outdoor > 75 or indoor > 50 %}auto
         {% elif outdoor > 25 or indoor > 15 %}auto
         {% elif indoor < 5 %}night
         {% else %}auto{% endif %}
       '';
     }];
   }
   ```

3. **Safe to Open Windows**

   ```nix
   {
     binary_sensor = [{
       name = "Safe to Ventilate (Living Room)";
       unique_id = "safe_to_ventilate_living_room";
       state = "{{ states('sensor.aleje_pm2_5') | float(999) < 15 and states('sensor.aleje_pm2_5') | float(999) < states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') | float(0) }}";
       device_class = "safety";
     }];
   }
   ```

4. **Filter Replacement Urgency**

   ```nix
   {
     sensor = [{
       name = "Air Purifier Filter Urgency";
       unique_id = "air_purifier_filter_urgency";
       state = ''
         {% set life = states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int(100) %}
         {% if life < 5 %}critical
         {% elif life < 10 %}urgent
         {% elif life < 20 %}soon
         {% else %}normal{% endif %}
       '';
       icon = ''
         {% set life = states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int(100) %}
         {% if life < 5 %}mdi:air-filter-remove
         {% elif life < 20 %}mdi:air-filter
         {% else %}mdi:air-filter{% endif %}
       '';
     }];
   }
   ```

5. **Antibacterial Run Due** (time-based tracking)

   ```nix
   {
     binary_sensor = [{
       name = "Antibacterial Filter Run Due";
       unique_id = "antibacterial_run_due";
       state = "{{ (now() - as_datetime(states('input_datetime.last_antibacterial_run'))).days > 7 }}";
       device_class = "problem";
     }];
   }
   ```

### Phase 2: Input Helpers ✅

**Add to automations.nix:**

```nix
input_boolean = {
  high_pollution_mode = {
    name = "High Pollution Mode";
    icon = "mdi:alert-circle";
  };
};

input_datetime = {
  last_antibacterial_run = {
    name = "Last Antibacterial Filter Run";
    has_date = true;
    has_time = true;
  };
};
```

### Phase 3: Core Automations (9 total) 🔄

**Status**: PR #192 created, pending CI/review

#### 1. Outdoor-Driven Mode Switching

```nix
{
  id = "air_purifier_outdoor_mode_switch";
  alias = "Air Purifier - Outdoor mode switching";
  description = "Adjust purifier mode based on outdoor PM2.5 levels";

  trigger = [{
    platform = "state";
    entity_id = "sensor.aleje_pm2_5";
  }];

  condition = [{
    condition = "state";
    entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
    state = "on";
  }];

  action = [{
    choose = [
      {
        conditions = [{
          condition = "numeric_state";
          entity_id = "sensor.aleje_pm2_5";
          above = 75;
        }];
        sequence = [{
          action = "fan.set_preset_mode";
          target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          data.preset_mode = "Auto";
        }];
      }
      {
        conditions = [{
          condition = "numeric_state";
          entity_id = "sensor.aleje_pm2_5";
          below = 15;
        }];
        sequence = [{
          action = "fan.set_preset_mode";
          target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          data.preset_mode = "Night";
        }];
      }
    ];
    default = [{
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Auto";
    }];
  }];

  mode = "restart";
}
```

#### 2. Indoor Quality Boost

```nix
{
  id = "air_purifier_indoor_boost";
  alias = "Air Purifier - Indoor quality boost";
  description = "Boost purification when indoor PM2.5 exceeds threshold";

  trigger = [{
    platform = "numeric_state";
    entity_id = "sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6";
    above = 25;
    for.minutes = 5;
  }];

  action = [
    {
      action = "fan.turn_on";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
    }
    {
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Auto";
    }
  ];

  mode = "single";
}
```

#### 3. Adaptive Sleep Mode

```nix
{
  id = "air_purifier_sleep_mode";
  alias = "Air Purifier - Adaptive sleep mode";
  description = "Auto if outdoor PM2.5 >75, else Night mode during sleep hours";

  trigger = [
    { platform = "time"; at = "21:00:00"; }
    {
      platform = "state";
      entity_id = "sensor.aleje_pm2_5";
    }
  ];

  condition = [{
    condition = "time";
    after = "21:00:00";
    before = "07:00:00";
  }];

  action = [{
    choose = [
      {
        conditions = [{
          condition = "numeric_state";
          entity_id = "sensor.aleje_pm2_5";
          above = 75;
        }];
        sequence = [{
          action = "fan.set_preset_mode";
          target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          data.preset_mode = "Auto";
        }];
      }
    ];
    default = [{
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Night";
    }];
  }];

  mode = "restart";
}
```

#### 4. Morning/Evening Ventilation Safety

```nix
{
  id = "air_purifier_ventilation_reminder";
  alias = "Air Purifier - Ventilation safety reminder";
  description = "TTS reminder when outdoor AQ is better than indoor";

  trigger = [
    { platform = "time"; at = "07:00:00"; }
    { platform = "time"; at = "21:00:00"; }
  ];

  condition = [{
    condition = "state";
    entity_id = "binary_sensor.safe_to_ventilate_living_room";
    state = "on";
  }];

  action = [{
    action = "tts.speak";
    target.entity_id = "tts.piper";
    data = {
      media_player_entity_id = "media_player.vlc_telnet";
      message = "Możesz otworzyć okno w salonie, powietrze na zewnątrz lepsze niż w środku. PM2.5 zewnątrz {{ states('sensor.aleje_pm2_5') }}, wewnątrz {{ states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') }} mikrogramów.";
    };
  }];

  mode = "single";
}
```

#### 5. Away Mode Energy Optimization

```nix
{
  id = "air_purifier_away_mode";
  alias = "Air Purifier - Away mode optimization";
  description = "Adjust operation based on outdoor AQ during away mode";

  trigger = [{
    platform = "state";
    entity_id = "input_boolean.away_mode";
    to = "on";
  }];

  action = [{
    choose = [
      {
        conditions = [{
          condition = "numeric_state";
          entity_id = "sensor.aleje_pm2_5";
          below = 25;
        }];
        sequence = [{
          action = "fan.turn_off";
          target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
        }];
      }
      {
        conditions = [{
          condition = "numeric_state";
          entity_id = "sensor.aleje_pm2_5";
          above = 50;
        }];
        sequence = [{
          action = "fan.set_preset_mode";
          target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
          data.preset_mode = "Auto";
        }];
      }
    ];
    default = [{
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Night";
    }];
  }];

  mode = "restart";
}
```

#### 6. Filter Replacement - Todoist Task

```nix
{
  id = "air_purifier_filter_replacement_todoist";
  alias = "Air Purifier - Filter replacement Todoist";
  description = "Create Todoist task when filter needs replacement";

  trigger = [
    {
      platform = "numeric_state";
      entity_id = "sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3";
      below = 20;
    }
    {
      platform = "event";
      event_type = "filter_eof";
      event_data.entity_id = "event.zhimi_de_334622045_mb3_filter_eof_e_9_1";
    }
  ];

  action = [{
    action = "todoist.new_task";
    data = {
      content = "Wymień filtr HEPA oczyszczacza powietrza ({{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }}% pozostało)";
      project = "Dom";
      priority = 3;
      due_date_string = "za 2 tygodnie";
      due_date_lang = "pl";
      labels = "dom,konserwacja";
      description = ''Filtr zużyty w {{ 100 - states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int }}%.

Link do filtra: https://allegro.pl/xiaomi-air-purifier-3h-filter
Aktualny czas pracy: {{ states('sensor.zhimi_de_334622045_mb3_filter_used_time_p_4_5') }}h'';
    };
  }];

  mode = "single";
}
```

#### 7. Filter Replacement - TTS Alert

```nix
{
  id = "air_purifier_filter_tts_alert";
  alias = "Air Purifier - Filter TTS alert";
  description = "Voice alert for critical filter levels";

  trigger = [{
    platform = "numeric_state";
    entity_id = "sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3";
    below = 10;
  }];

  action = [{
    action = "tts.speak";
    target.entity_id = "tts.piper";
    data = {
      media_player_entity_id = "media_player.vlc_telnet";
      message = "Uwaga! Filtr oczyszczacza powietrza wymaga wymiany. Pozostało tylko {{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }} procent żywotności.";
    };
  }];

  mode = "single";
}
```

#### 8. Antibacterial Filter - Auto Run

```nix
{
  id = "air_purifier_antibacterial_auto";
  alias = "Air Purifier - Antibacterial auto run";
  description = "Automatic weekly antibacterial filter activation (high power run)";

  trigger = [{
    platform = "time_pattern";
    hours = "3";
    minutes = "0";
  }];

  condition = [
    {
      condition = "time";
      weekday = ["sun"];
    }
    {
      condition = "template";
      value_template = "{{ (now() - as_datetime(states('input_datetime.last_antibacterial_run'))).days >= 7 }}";
    }
  ];

  action = [
    {
      action = "fan.turn_on";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
    }
    {
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Auto";
    }
    { delay.hours = 2; }
    {
      action = "input_datetime.set_datetime";
      target.entity_id = "input_datetime.last_antibacterial_run";
      data.datetime = "{{ now().isoformat() }}";
    }
  ];

  mode = "single";
}
```

#### 9. Daily Auto-Start

```nix
{
  id = "air_purifier_daily_start";
  alias = "Air Purifier - Daily auto-start";
  description = "Ensure purifier runs during occupied hours";

  trigger = [
    { platform = "time"; at = "07:00:00"; }
  ];

  condition = [{
    condition = "state";
    entity_id = "input_boolean.away_mode";
    state = "off";
  }];

  action = [
    {
      action = "fan.turn_on";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
    }
    {
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Auto";
    }
  ];

  mode = "single";
}
```

### Phase 4: Polish Voice Commands ⬜

**File**: `hosts/homelab/home-assistant/intents.nix`

**Add 7 intent handlers:**

```nix
TurnOnAirPurifier = {
  speech.text = "Włączam oczyszczacz powietrza w salonie";
  action = [{
    action = "fan.turn_on";
    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
  }];
};

TurnOffAirPurifier = {
  speech.text = "Wyłączam oczyszczacz powietrza";
  action = [{
    action = "fan.turn_off";
    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
  }];
};

SetAirPurifierNight = {
  speech.text = "Ustawiam oczyszczacz w tryb nocny";
  action = [{
    action = "fan.set_preset_mode";
    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
    data.preset_mode = "Night";
  }];
};

SetAirPurifierAuto = {
  speech.text = "Ustawiam oczyszczacz w tryb automatyczny";
  action = [{
    action = "fan.set_preset_mode";
    target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
    data.preset_mode = "Auto";
  }];
};

GetAirQuality = {
  speech.text = ''
    Jakość powietrza w salonie: wewnątrz {{ states('sensor.zhimi_de_334622045_mb3_pm2_5_density_p_3_6') }} mikrogramów PM2.5,
    na zewnątrz {{ states('sensor.aleje_pm2_5') }} mikrogramów.
    {{ 'Możesz otworzyć okno.' if is_state('binary_sensor.safe_to_ventilate_living_room', 'on') else 'Lepiej zostaw okna zamknięte.' }}
  '';
};

GetFilterStatus = {
  speech.text = "Filtr oczyszczacza zużyty w {{ 100 - states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') | int }} procentach. Pozostało {{ states('sensor.zhimi_de_334622045_mb3_filter_life_level_p_4_3') }} procent żywotności.";
};

TriggerAntibacterial = {
  speech.text = "Uruchamiam tryb antybakteryjny oczyszczacza na 2 godziny";
  action = [
    {
      action = "fan.set_preset_mode";
      target.entity_id = "fan.zhimi_de_334622045_mb3_s_2_air_purifier";
      data.preset_mode = "Auto";
    }
    {
      action = "input_datetime.set_datetime";
      target.entity_id = "input_datetime.last_antibacterial_run";
      data.datetime = "{{ now().isoformat() }}";
    }
  ];
};
```

**File**: `custom_sentences/pl/air_quality.yaml`

```yaml
language: "pl"
lists:
  skip_words:
    values:
      - "proszę"
      - "może"
      - "mi"
      - "no"

intents:
  TurnOnAirPurifier:
    data:
      - required_keywords: [włącz, oczyszczacz]
        sentences:
          - "(włącz|uruchom|zapal) oczyszczacz [powietrza]"
          - "włącz filtr powietrza"

  TurnOffAirPurifier:
    data:
      - required_keywords: [wyłącz, oczyszczacz]
        sentences:
          - "(wyłącz|zatrzymaj|zgaś) oczyszczacz [powietrza]"
          - "wyłącz filtr powietrza"

  SetAirPurifierNight:
    data:
      - required_keywords: [oczyszczacz, nocny]
        sentences:
          - "oczyszczacz [w] tryb (nocny|cichy)"
          - "(ustaw|przełącz) oczyszczacz na (nocny|cichy)"

  SetAirPurifierAuto:
    data:
      - required_keywords: [oczyszczacz, auto]
        sentences:
          - "oczyszczacz [w] tryb (auto|automatyczny)"
          - "(ustaw|przełącz) oczyszczacz na auto"

  GetAirQuality:
    data:
      - required_keywords: [jakość, powietrza]
        sentences:
          - "jaka [jest] jakość powietrza"
          - "sprawdź (jakość powietrza|powietrze)"
          - "jak (jest|wygląda) powietrze"

  GetFilterStatus:
    data:
      - required_keywords: [filtr, stan]
        sentences:
          - "(jaki|jak) [jest] stan filtra"
          - "ile [zostało] filtra"
          - "sprawdź filtr [oczyszczacza]"

  TriggerAntibacterial:
    data:
      - required_keywords: [antybakteryjny, tryb]
        sentences:
          - "(włącz|uruchom) tryb antybakteryjny"
          - "tryb antybakteryjny oczyszczacza"
```

### Phase 5: Component Configuration ⬜

**File**: `hosts/homelab/home-assistant/default.nix`

Verify Xiaomi Home component already added (done in Phase 1).

## Key Thresholds & Logic

| Metric | Threshold | Action |
| ------ | --------- | ------ |
| Outdoor PM2.5 | <15 µg/m³ | Night mode if indoor good |
| Outdoor PM2.5 | 15-75 µg/m³ | Auto mode |
| Outdoor PM2.5 | >75 µg/m³ | Auto mode (even during sleep) |
| Indoor PM2.5 | >25 µg/m³ | Boost to Auto for 30min |
| Indoor PM2.5 | Target: <5 µg/m³ | WHO 2021 guideline |
| Filter Life | <20% | Todoist task (2 weeks) |
| Filter Life | <10% | TTS alert |
| Filter Life | <5% | Critical (daily TTS) |
| Antibacterial | Weekly | Auto run Sunday 3 AM, 2h |
| Sleep Hours | 21:00-07:00 | Adaptive (Auto if PM2.5>75, else Night) |
| Safe Ventilate | Outdoor <15 AND < indoor | TTS reminder 07:00, 21:00 |
| Away Mode | Outdoor <25 | Turn off (energy save) |
| Away Mode | Outdoor 25-50 | Night mode |
| Away Mode | Outdoor >50 | Auto mode (protection) |

## Testing Checklist

- [ ] Template sensors report correct values
- [ ] Outdoor mode switching works (test by changing GIOS data)
- [ ] Indoor boost triggers at PM2.5 >25
- [ ] Sleep mode switches to Night at 21:00 (if outdoor <75)
- [ ] Ventilation TTS fires when outdoor < indoor
- [ ] Away mode energy optimization
- [ ] Todoist task created at filter <20%
- [ ] TTS alert at filter <10%
- [ ] Antibacterial runs Sunday 3 AM
- [ ] Voice commands work: "Włącz oczyszczacz", "Jaka jakość powietrza"
- [ ] Filter status query accurate

## Immediate Actions

**URGENT - Filter Replacement:**

- [ ] Order HEPA filter (current: 15% life, 2966h)
- [ ] Link: <https://allegro.pl/xiaomi-air-purifier-3h-filter>
- [ ] Expected delivery: 2 weeks
- [ ] Install when delivered
- [ ] Reset filter counter via button entity

## Next Steps

1. ✅ ~~Create feature branch: `feat/air-purifier-automation`~~
2. ✅ ~~Add template sensors (Phase 1)~~ - Merged via #189
3. ✅ ~~Add input helpers (Phase 2)~~ - Merged via #189
4. ✅ ~~Add automations incrementally (Phase 3)~~ - Merged via #192
5. 🔄 Add voice commands (Phase 4) - in PR
6. ⬜ Test voice commands with real device
7. ⬜ Monitor Phase 3+4 together (1 week)
8. ⬜ Tune thresholds based on monitoring
9. ⬜ Order replacement filter

## Future Enhancements

- [ ] OpenWeatherMap AQ forecast integration (predictive pre-run)
- [ ] Multi-room expansion (bedroom purifier)
- [ ] Dashboard cards for AQ visualization
- [ ] Historical PM2.5 tracking (Grafana)
- [ ] Pollen data integration (spring allergies)
- [ ] Filter efficiency tracking (indoor/outdoor ratio over time)
- [ ] Energy consumption monitoring
- [ ] Integration with window sensors (auto-off when open)

## References

- [Xiaomi Air Purifier 3H Manual](https://i01.appmifile.com/webfile/globalimg/Global_UG/Mi_Ecosystem/Mi_Air_Purifier_3H/en_V2.pdf)
- [WHO Air Quality Guidelines 2021](https://www.who.int/news-room/feature-stories/detail/what-are-the-who-air-quality-guidelines)
- [GIOS Poland AQ Data](https://powietrze.gios.gov.pl/pjp/current)
- [Home Assistant Fan Integration](https://www.home-assistant.io/integrations/fan/)
- [Todoist Integration](https://www.home-assistant.io/integrations/todoist/)
