
#!/usr/bin/env python3
"""
quick_test.py
─────────────
Super quick test - just provide an image and get audio!

Usage: python quick_test.py your_image.jpg
"""

import sys
import base64
import requests
from pathlib import Path

if len(sys.argv) < 2:
    print("Usage: python quick_test.py <image_path>")
    print("Example: python quick_test.py barriers.jpg")
    sys.exit(1)

image_path = sys.argv[1]

if not Path(image_path).exists():
    print(f"❌ Error: File '{image_path}' not found!")
    sys.exit(1)

print(f"\n🔄 Testing with: {image_path}")
print("="*60)

try:
    with open(image_path, 'rb') as f:
        response = requests.post(
            'http://127.0.0.1:8000/predict-with-audio',
            files={'file': f},
            params={
                'direction': 'front',
                'distance': 'close',
                'voice': 'en-US-female-1'
            },
            timeout=30
        )
    
    if response.status_code == 200:
        data = response.json()
        
        print(f"\n🗣️  Feedback: {data['text_feedback']}")
        
        print(f"\n🎯 Predictions:")
        for pred in data['predictions']:
            print(f"   • {pred['label']}: {pred['confidence']:.1f}%")
        
        # Save audio
        audio = base64.b64decode(data['audio_base64'])
        audio_file = f"output_{Path(image_path).stem}.mp3"
        Path(audio_file).write_bytes(audio)
        
        print(f"\n🔊 Audio: {audio_file}")
        print(f"   Size: {len(audio):,} bytes")
        print(f"\n💡 Play: vlc {audio_file}")
        print("="*60 + "\n")
        
    else:
        print(f"❌ Error {response.status_code}: {response.text}")

except requests.exceptions.ConnectionError:
    print("\n❌ Cannot connect to server!")
    print("   Start server: python main_with_audio.py")
except Exception as e:
    print(f"\n❌ Error: {e}")