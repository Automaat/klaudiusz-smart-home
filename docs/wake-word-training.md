# Training Polish Wake Word "Klaudiusz" with openWakeWord

Guide for training custom Polish wake word using openWakeWord and Piper TTS for Wyoming/Home Assistant integration.

## Prerequisites

- Python 3.8+
- Google Colab account (free tier sufficient)
- Home Assistant with Wyoming integration
- Basic familiarity with command line

## Overview

Training a Polish wake word involves:
1. Generating synthetic Polish audio samples using Piper TTS
2. Training openWakeWord model with those samples
3. Deploying model to Home Assistant
4. Testing and refining

## Important Limitations

⚠️ **Known Issues:**
- openWakeWord's embedding model may have been trained only on English data
- Polish wake words are experimental - accuracy may be lower than English
- May require multiple training iterations and tuning

## Step 1: Generate Polish Audio Samples

### Install piper-sample-generator

```bash
git clone https://github.com/rhasspy/piper-sample-generator.git
cd piper-sample-generator
pip install -r requirements.txt
```

### Download Polish Piper Voice Models

Available Polish voices from [Piper Voices](https://github.com/rhasspy/piper/blob/master/VOICES.md):
- `pl_PL-darkman-medium`
- `pl_PL-gosia-medium`
- `pl_PL-mc_speech-medium`
- `pl_PL-mls_6892-low`

Download voices from [Hugging Face](https://huggingface.co/rhasspy/piper-voices):

```bash
# Download Polish voice (example: gosia)
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/pl/pl_PL/gosia/medium/pl_PL-gosia-medium.onnx
wget https://huggingface.co/rhasspy/piper-voices/resolve/main/pl/pl_PL/gosia/medium/pl_PL-gosia-medium.onnx.json

# Repeat for other voices to get variety
```

### Generate Samples

```bash
# Generate samples for "klaudiusz" using Polish voice
python3 generate_samples.py 'klaudiusz' \
  --voice pl_PL-gosia-medium \
  --output-dir samples/klaudiusz \
  --num-samples 1000

# Repeat with other Polish voices for diversity
python3 generate_samples.py 'klaudiusz' \
  --voice pl_PL-darkman-medium \
  --output-dir samples/klaudiusz \
  --num-samples 1000
```

**Note:** If v3 doesn't support Polish voices out-of-the-box, see "Workaround for Single-Speaker Models" section below.

## Step 2: Train openWakeWord Model

### Option A: Google Colab (Recommended)

1. Open [openWakeWord Automatic Training Notebook](https://colab.research.google.com/github/dscripka/openWakeWord/blob/main/notebooks/automatic_model_training.ipynb)

2. Upload your generated samples to Colab:
   ```python
   from google.colab import files
   # Upload samples/klaudiusz folder as zip
   ```

3. Configure training in the notebook:
   ```yaml
   # In the YAML config section
   target_word: 'klaudiusz'
   language: 'pl'  # Polish
   positive_sample_dir: '/content/samples/klaudiusz'
   ```

4. Run training cells sequentially

5. Download resulting `.tflite` model file

### Option B: Local Training

```bash
git clone https://github.com/dscripka/openWakeWord.git
cd openWakeWord

# Install dependencies
pip install -r requirements.txt

# Create config file
cat > configs/klaudiusz_pl.yaml <<EOF
# Training configuration for Polish wake word "Klaudiusz"
target_word: "klaudiusz"
language: "pl"
positive_sample_dir: "../piper-sample-generator/samples/klaudiusz"
negative_sample_dir: "data/background_noise"  # Use default English noise
model_type: "simple"
training_steps: 5000
batch_size: 32
EOF

# Run training
python train.py --config configs/klaudiusz_pl.yaml
```

### Expected Output

Training produces:
- `klaudiusz.tflite` - Optimized model for deployment
- `klaudiusz_metrics.json` - Performance metrics
- Training logs

## Step 3: Deploy to Home Assistant

### Copy Model to Wyoming openWakeWord

```bash
# On your Home Assistant system
mkdir -p /share/openwakeword
cp klaudiusz.tflite /share/openwakeword/pl_klaudiusz.tflite
```

### Restart Wyoming openWakeWord

```bash
# Via Home Assistant UI:
# Settings > Add-ons > Wyoming openWakeWord > Restart

# Or via command line on host:
docker restart addon_core_openwakeword
```

### Configure Voice Assistant

1. Navigate to: Settings > Voice assistants > [Your Assistant]
2. Wake word engine: `openWakeWord`
3. Wake word: `pl_klaudiusz`
4. Save

## Step 4: Testing

### Test in Home Assistant

1. Go to Settings > Voice assistants > [Your Assistant]
2. Click microphone icon
3. Say "Klaudiusz" in Polish
4. Check logs if not detecting:
   ```bash
   docker logs addon_core_openwakeword -f
   ```

### Debugging Tips

**Low Detection Rate:**
- Record more diverse samples (different tones, speeds)
- Try different Polish Piper voices
- Adjust detection threshold in Wyoming config
- Add background noise during training

**False Positives:**
- Increase detection threshold
- Add more negative samples (common Polish words)
- Train longer (more epochs)

**Not Detecting at All:**
- Verify model file copied correctly
- Check Wyoming logs for errors
- Test with English wake word first (sanity check)
- Ensure microphone working

## Step 5: Refinement

### Collect Real Audio

Record yourself saying "Klaudiusz" 50-100 times:
```bash
# Use arecord or Home Assistant's voice debug tool
arecord -f S16_LE -r 16000 -c 1 -d 2 klaudiusz_real_01.wav
```

### Retrain with Real Samples

Mix synthetic Piper samples with real recordings:
```bash
# Combine samples
cp real_recordings/*.wav samples/klaudiusz/

# Retrain
python train.py --config configs/klaudiusz_pl.yaml
```

### Iterate

- Test with family members (different voices)
- Try variations: "hej Klaudiusz", "Klaudiuszu" (vocative case)
- Monitor false positive rate over days

## Workaround for Single-Speaker Models

If piper-sample-generator v3 doesn't work with Polish voices:

### Convert Piper Checkpoint to .pt Format

```python
# In piper_train repository
import torch
from piper_train.vits.models import VitsModel

# Load checkpoint
ckpt = torch.load('pl_PL-gosia-medium.ckpt')
model = VitsModel.load_from_checkpoint('pl_PL-gosia-medium.ckpt')

# Save model only
torch.save(model.model_g, 'pl_PL-gosia-medium.pt')
```

### Modify generate_samples.py

For single-speaker models, modify `generate_audio` function:
```python
# Around line 150-160 in generate_samples.py
def generate_audio(...):
    # For single-speaker models
    if not hasattr(model, 'emb_g'):
        g = None  # Don't use speaker embedding
    else:
        g = ...  # Original code
```

## Integration with NixOS Configuration

### Add Model to Flake

```nix
# hosts/homelab/home-assistant/default.nix
{
  services.wyoming.openwakeword = {
    enable = true;
    customModelsDirectories = [
      ./wake-words  # Add custom wake words here
    ];
  };
}
```

### Store Model in Git (Optional)

```bash
# Create wake-words directory in repo
mkdir -p hosts/homelab/home-assistant/wake-words
cp klaudiusz.tflite hosts/homelab/home-assistant/wake-words/
git add hosts/homelab/home-assistant/wake-words/klaudiusz.tflite
git commit -s -S -m "Add Polish wake word 'Klaudiusz'"
```

## Contributing to Community

Once you have a working model, consider contributing to:
- [fwartner/home-assistant-wakewords-collection](https://github.com/fwartner/home-assistant-wakewords-collection)

### Contribution Steps

1. Fork repository
2. Create directory: `pl/klaudiusz/`
3. Add files:
   ```
   pl/klaudiusz/
   ├── klaudiusz.tflite
   ├── README.md  # Training details, performance metrics
   └── config.yaml  # Training configuration used
   ```
4. Submit PR with:
   - Detection accuracy metrics
   - False positive rate
   - Tested voices/accents
   - Training dataset details

## Performance Expectations

Based on English wake word benchmarks:
- **Ideal:** >95% detection rate, <1 false alarm per 10 hours
- **Polish (experimental):** Expect 80-90% detection, higher false positive rate
- **Real-world:** Performance depends heavily on:
  - Microphone quality
  - Background noise
  - Speaker accent/pronunciation
  - Training data diversity

## Troubleshooting

### "Module 'emb_g' not found"
Polish Piper voices might be single-speaker models. Use workaround above.

### "Audio embedding dimension mismatch"
openWakeWord's embedding model expects English features. Try:
- Training longer to adapt
- Using phonetically similar English word first (e.g., "Claudius")
- Waiting for official multilingual openWakeWord release

### Wyoming Not Loading Model
Check file permissions:
```bash
chmod 644 /share/openwakeword/pl_klaudiusz.tflite
chown root:root /share/openwakeword/pl_klaudiusz.tflite
```

## Alternative Approaches

If openWakeWord doesn't work well for Polish:

### 1. Porcupine (Commercial)
- Contact Picovoice about Polish support
- May require paid tier
- Instant training, no ML expertise needed

### 2. Raven (Template-Based)
- Record 3-5 templates of "Klaudiusz"
- Lower accuracy but guaranteed Polish support
- Configure in Rhasspy/Home Assistant

### 3. Wait for Official Support
- openWakeWord roadmap includes multilingual support
- Piper voices improving continuously
- Community actively working on non-English wake words

## References

- [openWakeWord GitHub](https://github.com/dscripka/openWakeWord)
- [piper-sample-generator](https://github.com/rhasspy/piper-sample-generator)
- [Piper TTS Voices](https://github.com/rhasspy/piper/blob/master/VOICES.md)
- [Wyoming Protocol](https://github.com/rhasspy/wyoming)
- [Home Assistant Wake Word Guide](https://www.home-assistant.io/voice_control/create_wake_word/)
- [Polish Language Support Discussion](https://github.com/rhasspy/piper-sample-generator/issues/4)
- [openWakeWord Multilingual Discussion](https://github.com/dscripka/openWakeWord/discussions/52)

## Success Metrics

Document your results:
- [ ] Model trains without errors
- [ ] Detects "Klaudiusz" at >80% rate
- [ ] False positives <5 per hour
- [ ] Works with multiple speakers
- [ ] Survives background music/TV
- [ ] Response time <500ms

Once stable, share metrics with community!
