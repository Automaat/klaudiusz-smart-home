# Custom Voice Options for Klaudiusz Smart Home

## Current Setup

- **TTS Engine**: Piper
- **Current Voice**: `pl_PL-darkman-medium`
- **Language**: Polish (pl)
- **Port**: 10200

## Available Polish Voices for Piper

### Built-in Voices

- `pl_PL-darkman-medium` (currently used)
- `pl_PL-gosia-medium` (female voice)
- `pl_PL-mc_speech-medium`
- `pl_PL-mls_6892-low` (lower quality)

### Community Polish Voices by WitoldG

Higher quality models available on [Hugging Face](https://huggingface.co/WitoldG/polish_piper_models):

- `pl_PL-meski_wg_glos-medium` (male voice)
- `pl_PL-zenski_wg_glos-medium` (female voice)
- `pl_PL-jarvis_wg_glos-medium`
- `pl_PL-justyna_wg_glos-medium`

Users report "Zenski" and "Meski" as particularly good quality.

## Option 1: Switch to Different Pre-trained Voice

### Implementation in NixOS

```nix
# In hosts/homelab/home-assistant/default.nix
services.wyoming.piper.servers.default = {
  enable = true;
  voice = "pl_PL-gosia-medium";  # or any other voice
  uri = "tcp://0.0.0.0:10200";
};
```

### Using WitoldG's Custom Voices

1. Download models from [WitoldG's repository](https://huggingface.co/WitoldG/polish_piper_models)
2. Place `.onnx` and `.json` files in `/var/lib/piper-voices/`
3. Configure:

```nix
services.wyoming.piper.servers.default = {
  enable = true;
  voice = "pl_PL-meski_wg_glos-medium";
  uri = "tcp://0.0.0.0:10200";
  extraArgs = [
    "--download-dir" "/var/lib/piper-voices"
  ];
};
```

## Option 2: Train Your Own Custom Voice

### Requirements

- **Audio Data**: 5-60 minutes of clean recordings
- **Hardware**: NVIDIA GPU (local) or Google Colab (cloud)
- **Format**: 22050 Hz sample rate, mono

### Training Tools

#### TextyMcSpeechy

[GitHub Repository](https://github.com/domesticatedviking/TextyMcSpeechy)

- Easiest method for beginners
- Supports RVC voice integration
- Works offline on Raspberry Pi
- Listen to model while training

#### Piper Recording Studio

- Official tool for dataset collection
- Structured recording interface
- Automatic text alignment

#### Training Process

1. **Record Dataset**

   ```bash
   # Use Piper Recording Studio or record manually
   # Need Polish text corpus + your voice recordings
   ```

2. **Preprocess**

   ```bash
   python3 -m piper_train.preprocess \
     --language pl \
     --input-dir ~/piper/my-dataset \
     --output-dir ~/piper/my-training \
     --dataset-format ljspeech \
     --single-speaker \
     --sample-rate 22050
   ```

3. **Train from Polish Checkpoint**
   - Download existing Polish model as base
   - Fine-tune with your recordings (faster than training from scratch)
   - 6,000-10,000 epochs typically sufficient

4. **Export to ONNX**
   - Convert trained model for deployment
   - Create config JSON file

### Google Colab Method (No GPU Required)

- Use free Google Colab notebooks
- Access to high-powered GPUs
- Training time: few hours vs days on CPU

### Quick Training with Minimal Data

[Cal Bryant's method](https://calbryant.uk/blog/training-a-new-ai-voice-for-piper-tts-with-only-4-words/):

- Train with as little as 4 words using Chatterbox TTS
- Generate synthetic dataset from single phrase
- Fine-tune Piper with generated data

## Option 3: Character Voices (Darth Vader, Terminator, etc.)

### Available Pre-trained RVC Models

#### Darth Vader

- [James Earl Jones version](https://huggingface.co/0x3e9/Darth_Vader_RVC) (500-1k epochs)
- Trained on all Star Wars movies
- Download: `Darth Vader Ultimate.zip`

#### Arnold Schwarzenegger/Terminator

- [Terminator 3 game voice](https://huggingface.co/sail-rvc/ArnoldSchwarzenegger)
- Multiple versions available (movies, audiobooks)
- 75-300 epochs trained

### RVC (Retrieval-based Voice Conversion)

#### What is RVC?

- Post-processes TTS output to change voice characteristics
- Requires only 18 minutes of training data for good results
- RVC v2 uses 756-dimensional feature vectors (vs 256 in v1)

#### Implementation Pipeline

```text
Text → Piper TTS (Polish) → RVC Model → Character Voice → Audio Effects → Output
```

#### Setup Requirements

1. RVC inference server (Python-based)
2. Model files (.pth and .index)
3. Audio post-processing (Sox/FFmpeg)

### Character Voice Effects with RVC

#### Darth Vader Voice Settings

- Pitch shift: -3 to -5 semitones
- Add breathing sounds
- Robotic filter/vocoder effect
- Slight echo/reverb

#### Terminator

- Monotone delivery
- Metallic resonance
- Remove emotion variations
- Slight distortion

### Platforms for RVC Models

- [Voice-Models.com](https://voice-models.com/) - 27,900+ models
- [Weights.com](https://www.weights.com) - Easy web interface
- [Hugging Face](https://huggingface.co/spaces/zomehwh/rvc-models) - Free models

## Option 4: Advanced AI Voice Cloning

### Coqui TTS with XTTS-v2

[GitHub Repository](https://github.com/coqui-ai/TTS)

#### Features

- Zero-shot cloning from 6-second sample
- Supports 17 languages including Polish
- Emotion and style transfer
- Cross-language voice cloning
- Streaming with <200ms latency

#### Implementation

```python
# Install Coqui TTS
pip install TTS

# Clone voice from sample
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
tts.tts_to_file(
    text="Witaj w domu",
    language="pl",
    speaker_wav="your_voice_sample.wav",
    file_path="output.wav"
)
```

#### Limitations

- Real-time performance still improving
- Higher resource requirements than Piper
- Coqui company shut down (Dec 2023) but code still maintained

### AllTalk TTS

Based on Coqui engine with additional features:

- Settings page and GUI
- Low VRAM support
- DeepSpeed optimization
- Narrator mode
- Model fine-tuning
- JSON API for integration

## Implementation Strategies

### Strategy 1: Quick Win

1. Try WitoldG's `zenski` or `meski` voices
2. Simple config change in NixOS
3. Immediate improvement in voice quality

### Strategy 2: Custom Voice Training

1. Record 30-60 minutes of Polish text
2. Train using Google Colab (free GPU)
3. Deploy custom model to NixOS

### Strategy 3: Character Voice Pipeline

1. Keep current Polish Piper
2. Add RVC post-processing service
3. Download character RVC models
4. Configure audio effects chain

### Strategy 4: Full Replacement

1. Replace Piper with Coqui XTTS
2. Clone any voice with 6-second sample
3. Support multiple voices dynamically

## NixOS Configuration Examples

### Multiple Voice Servers

```nix
services.wyoming.piper.servers = {
  default = {
    enable = true;
    voice = "pl_PL-darkman-medium";
    uri = "tcp://0.0.0.0:10200";
  };
  female = {
    enable = true;
    voice = "pl_PL-gosia-medium";
    uri = "tcp://0.0.0.0:10201";
  };
  custom = {
    enable = true;
    voice = "pl_PL-my-custom-voice";
    uri = "tcp://0.0.0.0:10202";
    extraArgs = [
      "--download-dir" "/var/lib/piper-voices"
    ];
  };
};
```

### With RVC Post-Processing (Conceptual)

```nix
# Would require custom NixOS module
services.rvc-processor = {
  enable = true;
  inputPort = 10200;  # From Piper
  outputPort = 10210;  # To Home Assistant
  models = {
    darth-vader = "/var/lib/rvc-models/darth-vader.pth";
    terminator = "/var/lib/rvc-models/terminator.pth";
  };
};
```

## Testing Commands

```bash
# Check Piper service
systemctl status wyoming-piper-default

# Test TTS directly
echo "Witaj w domu" | piper --model pl_PL-gosia-medium --output test.wav

# Monitor logs
journalctl -u wyoming-piper-default -f

# Restart after config change
sudo systemctl restart wyoming-piper-default
```

## Resources

### Official Documentation

- [Piper GitHub](https://github.com/rhasspy/piper)
- [Piper Voice Samples](https://rhasspy.github.io/piper-samples/)
- [Wyoming Protocol](https://github.com/rhasspy/wyoming)

### Voice Models

- [Official Piper Voices](https://huggingface.co/rhasspy/piper-voices)
- [WitoldG Polish Models](https://huggingface.co/WitoldG/polish_piper_models)
- [RVC Models Collection](https://voice-models.com/)

### Training Guides

- [Create Custom Piper Voice](https://ssamjh.nz/create-custom-piper-tts-voice/)
- [4-Word Voice Training](https://calbryant.uk/blog/training-a-new-ai-voice-for-piper-tts-with-only-4-words/)
- [TextyMcSpeechy](https://github.com/domesticatedviking/TextyMcSpeechy)

### Community

- [Home Assistant Community](https://community.home-assistant.io/)
- [Piper Discussions](https://github.com/rhasspy/piper/discussions)
- [Voice.ai Discord](https://discord.gg/voice-ai)

## Notes

- Polish pronunciation may vary with character voices
- RVC adds 50-200ms latency
- Consider fallback to default voice for critical commands
- Test extensively with Polish diacritical marks (ł, ó, ą, ż, ę)
- Character voices work best with dramatic/announcement intents
