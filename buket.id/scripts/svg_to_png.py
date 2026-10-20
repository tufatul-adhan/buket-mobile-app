#!/usr/bin/env python3
"""
Convert SVG to PNG icon untuk berbagai ukuran Android
Menggunakan Pillow atau cairosvg jika tersedia
"""

import subprocess
import os
from pathlib import Path

def convert_with_ffmpeg(svg_path: str, png_path: str, size: int) -> bool:
    """Convert SVG ke PNG menggunakan FFmpeg"""
    try:
        cmd = f'ffmpeg -i "{svg_path}" -vf scale={size}:{size} -y "{png_path}"'
        result = subprocess.run(cmd, capture_output=True, shell=True, timeout=30)
        if result.returncode == 0:
            return True
        return False
    except Exception:
        return False

def convert_with_inkscape(svg_path: str, png_path: str, size: int) -> bool:
    """Convert SVG ke PNG menggunakan Inkscape"""
    try:
        # Inkscape command line
        cmd = f'inkscape "{svg_path}" -o "{png_path}" -w {size} -h {size}'
        result = subprocess.run(cmd, capture_output=True, shell=True, timeout=30)
        if result.returncode == 0:
            return True
        return False
    except Exception:
        return False

def try_convert_svg(svg_path: str, png_path: str, size: int) -> bool:
    """Try berbagai method untuk convert SVG ke PNG"""
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(png_path), exist_ok=True)
    
    # Method 1: FFmpeg
    if convert_with_ffmpeg(svg_path, png_path, size):
        print(f"✓ {size}x{size} generated with FFmpeg")
        return True
    
    # Method 2: Inkscape
    if convert_with_inkscape(svg_path, png_path, size):
        print(f"✓ {size}x{size} generated with Inkscape")
        return True
    
    # Method 3: Python libraries
    try:
        from PIL import Image, ImageDraw
        print(f"⚠ Fallback: Creating placeholder {size}x{size} with Pillow")
        # Create placeholder pink square with white center
        img = Image.new('RGBA', (size, size), (233, 30, 99, 0))  # Transparent pink
        # Draw simple circle in center
        draw = ImageDraw.Draw(img)
        margin = size // 6
        draw.ellipse([margin, margin, size-margin, size-margin], fill=(233, 30, 99, 255))
        img.save(png_path)
        return True
    except Exception as e:
        print(f"✗ Failed to create placeholder: {e}")
        return False

def main():
    print("🎀 Buket.id SVG to PNG Converter")
    print()
    
    svg_source = "assets/icons/bouquet_logo.svg"
    
    if not os.path.exists(svg_source):
        print(f"✗ SVG source not found: {svg_source}")
        return False
    
    # Android icon sizes
    sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
    }
    
    success_count = 0
    
    for dpi, size in sizes.items():
        output_path = f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png"
        print(f"Converting to {size}x{size}...")
        
        if try_convert_svg(svg_source, output_path, size):
            success_count += 1
            print(f"  → {output_path}")
        else:
            print(f"  ✗ Failed")
        print()
    
    print(f"\n✓ Generated {success_count}/{len(sizes)} icon variants")
    
    if success_count == 0:
        print("\n⚠ No icons generated. Please:")
        print("1. Install FFmpeg: https://ffmpeg.org/download.html")
        print("2. Or install Inkscape: https://inkscape.org/")
        print("3. Or use online converter: https://cloudconvert.com/svg-to-png")
        return False
    
    return True

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
