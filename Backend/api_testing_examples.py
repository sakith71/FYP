"""
api_testing_examples.py
───────────────────────
Examples for testing the audio-enabled API endpoints.

Run the server first:
    python main_with_audio.py

Then run these examples:
    python api_testing_examples.py
"""

import asyncio
import base64
import json
import requests
from pathlib import Path


# API base URL
BASE_URL = "http://127.0.0.1:8000"


# ─── Example 1: Get available voices ──────────────────────────────
def test_get_voices():
    """List all available TTS voices."""
    print("\n" + "="*60)
    print("Example 1: Get Available Voices")
    print("="*60)

    response = requests.get(f"{BASE_URL}/voices")
    data = response.json()

    print(f"\nDefault voice: {data['default']}")
    print(f"\nAvailable voices:")
    for voice_name, config in data['voices'].items():
        print(f"  - {voice_name}: {config}")


# ─── Example 2: Text-to-Speech only ───────────────────────────────
def test_text_to_speech():
    """Convert text to speech without image prediction."""
    print("\n" + "="*60)
    print("Example 2: Text-to-Speech Only")
    print("="*60)

    # Test 1: Get base64 JSON response
    params = {
        "text": "Barrier detected on your left side",
        "voice": "en-US-female-1",
        "rate": 1.0,
        "return_base64": True
    }

    response = requests.post(f"{BASE_URL}/text-to-speech", params=params)
    data = response.json()

    print(f"\nText: {data['text']}")
    print(f"Voice: {data['voice']}")
    print(f"Audio base64 length: {len(data['audio_base64'])} characters")

    # Save audio to file
    audio_bytes = base64.b64decode(data['audio_base64'])
    output_file = Path("test_audio_1.mp3")
    output_file.write_bytes(audio_bytes)
    print(f"✓ Saved to {output_file}")

    # Test 2: Get raw MP3 response
    params2 = {
        "text": "Pothole ahead, be careful",
        "voice": "en-US-male-1",
        "rate": 1.2,
        "return_base64": False
    }

    response2 = requests.post(f"{BASE_URL}/text-to-speech", params=params2)

    output_file2 = Path("test_audio_2.mp3")
    output_file2.write_bytes(response2.content)
    print(f"✓ Saved raw MP3 to {output_file2}")


# ─── Example 3: Predict with Audio ────────────────────────────────
def test_predict_with_audio(image_path: str = "test_image.jpg"):
    """Upload image and get predictions with audio feedback."""
    print("\n" + "="*60)
    print("Example 3: Image Prediction with Audio")
    print("="*60)

    if not Path(image_path).exists():
        print(f"Error: Image file '{image_path}' not found")
        print("Please provide a valid image path")
        return

    # Open and send image
    with open(image_path, 'rb') as f:
        files = {'file': f}
        params = {
            'direction': 'left',
            'distance': 'close',
            'voice': 'en-US-female-2',
            'rate': 1.1
        }

        response = requests.post(
            f"{BASE_URL}/predict-with-audio",
            files=files,
            params=params
        )

    if response.status_code == 200:
        data = response.json()

        print(f"\nPredictions:")
        for pred in data['predictions']:
            print(f"  - {pred['label']}: {pred['confidence']}%")
            if 'direction' in pred:
                print(f"    Direction: {pred['direction']}")
            if 'distance' in pred:
                print(f"    Distance: {pred['distance']}")

        print(f"\nText feedback: {data['text_feedback']}")

        # Save audio
        audio_bytes = base64.b64decode(data['audio_base64'])
        output_file = Path("prediction_audio.mp3")
        output_file.write_bytes(audio_bytes)
        print(f"✓ Audio saved to {output_file}")
    else:
        print(f"Error: {response.status_code}")
        print(response.json())


# ─── Example 4: WebSocket with Audio ──────────────────────────────
async def test_websocket_audio():
    """Test real-time WebSocket with audio feedback."""
    print("\n" + "="*60)
    print("Example 4: WebSocket Real-time with Audio")
    print("="*60)

    try:
        import websockets
    except ImportError:
        print("Please install websockets: pip install websockets")
        return

    # You need a test image
    image_path = Path("test_image.jpg")
    if not image_path.exists():
        print(f"Error: {image_path} not found")
        return

    # Read and encode image
    with open(image_path, 'rb') as f:
        image_bytes = f.read()
    image_base64 = base64.b64encode(image_bytes).decode('utf-8')

    # Connect to WebSocket
    uri = "ws://127.0.0.1:8000/ws/predict-audio"

    async with websockets.connect(uri) as websocket:
        print("✓ Connected to WebSocket")

        # Send frame with parameters
        message = {
            "frame": image_base64,
            "direction": "front",
            "distance": "close",
            "voice": "en-US-female-1",
            "rate": 1.0
        }

        await websocket.send(json.dumps(message))
        print("✓ Sent frame")

        # Receive response
        response = await websocket.recv()
        data = json.loads(response)

        print(f"\nPredictions:")
        for pred in data['predictions']:
            print(f"  - {pred['label']}: {pred['confidence']}%")

        print(f"\nText feedback: {data['text_feedback']}")
        print(f"Latency: {data['latency_ms']} ms")

        # Save audio
        audio_bytes = base64.b64decode(data['audio'])
        output_file = Path("websocket_audio.mp3")
        output_file.write_bytes(audio_bytes)
        print(f"✓ Audio saved to {output_file}")


# ─── Example 5: Different Directional Scenarios ───────────────────
def test_directional_scenarios(image_path: str = "test_image.jpg"):
    """Test different directional feedback scenarios."""
    print("\n" + "="*60)
    print("Example 5: Different Directional Scenarios")
    print("="*60)

    if not Path(image_path).exists():
        print(f"Error: {image_path} not found")
        return

    scenarios = [
        {"direction": "front", "distance": "close", "desc": "Object directly ahead, very close"},
        {"direction": "left", "distance": "medium", "desc": "Object on left, medium distance"},
        {"direction": "right", "distance": "far", "desc": "Object on right, far away"},
        {"direction": "center", "distance": None, "desc": "Object in center"},
    ]

    with open(image_path, 'rb') as f:
        image_data = f.read()

    for i, scenario in enumerate(scenarios, 1):
        print(f"\nScenario {i}: {scenario['desc']}")

        files = {'file': ('test.jpg', image_data, 'image/jpeg')}
        params = {
            'direction': scenario['direction'],
            'voice': 'en-US-female-1',
        }
        if scenario['distance']:
            params['distance'] = scenario['distance']

        response = requests.post(
            f"{BASE_URL}/predict-with-audio",
            files=files,
            params=params
        )

        if response.status_code == 200:
            data = response.json()
            print(f"  Feedback: {data['text_feedback']}")

            # Save audio with descriptive name
            audio_bytes = base64.b64decode(data['audio_base64'])
            filename = f"scenario_{i}_{scenario['direction']}.mp3"
            Path(filename).write_bytes(audio_bytes)
            print(f"  ✓ Saved to {filename}")


# ─── Example 6: Custom Voice Comparison ───────────────────────────
def test_voice_comparison():
    """Compare different voices saying the same thing."""
    print("\n" + "="*60)
    print("Example 6: Voice Comparison")
    print("="*60)

    text = "Barrier detected in front of you. Please stop."
    voices = ["en-US-female-1", "en-US-male-1", "en-GB-female"]

    for voice in voices:
        print(f"\nGenerating with voice: {voice}")

        params = {
            "text": text,
            "voice": voice,
            "return_base64": False
        }

        response = requests.post(f"{BASE_URL}/text-to-speech", params=params)

        if response.status_code == 200:
            filename = f"voice_{voice}.mp3"
            Path(filename).write_bytes(response.content)
            print(f"  ✓ Saved to {filename}")
        else:
            print(f"  ✗ Error: {response.status_code}")


# ─── Main ─────────────────────────────────────────────────────────
def main():
    """Run all examples."""
    print("\n" + "="*60)
    print("API Testing Examples")
    print("="*60)
    print("\nMake sure the server is running:")
    print("  python main_with_audio.py")
    print("\nStarting tests...\n")

    try:
        # Test basic endpoints
        test_get_voices()
        test_text_to_speech()

        # Test with image (you need to provide an image)
        print("\n" + "="*60)
        print("Note: For image-based tests, please provide 'test_image.jpg'")
        print("="*60)

        if Path("test_image.jpg").exists():
            test_predict_with_audio()
            test_directional_scenarios()

        # Test voice comparison
        test_voice_comparison()

        # Test WebSocket (requires websockets package)
        print("\n" + "="*60)
        print("WebSocket test requires: pip install websockets")
        print("="*60)
        try:
            asyncio.run(test_websocket_audio())
        except Exception as e:
            print(f"WebSocket test skipped: {e}")

        print("\n" + "="*60)
        print("All tests completed!")
        print("="*60)

    except Exception as e:
        print(f"\nError during testing: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()