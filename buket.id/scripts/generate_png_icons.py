#!/usr/bin/env python3
"""
Generate icon PNG files untuk Buket.id dengan Pillow
Membuat simple bouquet-themed icon tanpa bergantung SVG parsing
"""

def create_bouquet_icon(size: int, output_path: str) -> bool:
    """Create bouquet icon PNG using PIL"""
    try:
        from PIL import Image, ImageDraw
        import os
        
        # Ensure directory exists
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        # Colors
        PINK = (233, 30, 99)           # #E91E63
        LIGHT_PINK = (244, 143, 177)   # #F48FB1
        VERY_LIGHT_PINK = (248, 187, 208)  # #F8BBD0
        GREEN = (46, 125, 50)          # #2E7D32
        STEM_GREEN = (72, 187, 120)    # #48BB78
        WHITE = (255, 255, 255)
        TRANSPARENT = (255, 255, 255, 0)
        
        # Create image with transparent background
        img = Image.new('RGBA', (size, size), TRANSPARENT)
        draw = ImageDraw.Draw(img)
        
        # Scale factors
        scale = size / 200  # Base design is 200x200
        
        # Draw stems (simplified version)
        stem_width = max(1, int(3 * scale))
        stem_start_y = int(180 * scale)
        stem_mid_y = int(100 * scale)
        stem_end_y = int(50 * scale)
        
        draw.line([(int(100*scale), stem_start_y), 
                   (int(100*scale), stem_end_y)], 
                  fill=GREEN, width=stem_width)
        
        # Draw center flower (largest, red/pink)
        flower_r = int(12 * scale)
        center_x, center_y = int(100*scale), int(78*scale)
        
        # Main flower petals
        petal_positions = [
            (center_x, center_y - flower_r),      # top
            (center_x - int(12*scale), center_y + int(12*scale)),  # bottom-left
            (center_x + int(12*scale), center_y + int(12*scale)),  # bottom-right
            (center_x - int(14*scale), center_y),                  # left
            (center_x + int(14*scale), center_y),                  # right
        ]
        
        for px, py in petal_positions:
            draw.ellipse([px-flower_r, py-flower_r, px+flower_r, py+flower_r], 
                        fill=PINK)
        
        # Center of main flower
        center_r = int(8 * scale)
        draw.ellipse([center_x-center_r, center_y-center_r, 
                      center_x+center_r, center_y+center_r], 
                    fill=LIGHT_PINK)
        
        # Draw side flowers (smaller)
        side_flower_r = int(10 * scale)
        side_center_r = int(6 * scale)
        
        # Left flower
        left_x, left_y = int(55*scale), int(85*scale)
        draw.ellipse([left_x-side_flower_r, left_y-side_flower_r,
                      left_x+side_flower_r, left_y+side_flower_r],
                    fill=LIGHT_PINK)
        draw.ellipse([left_x-side_center_r, left_y-side_center_r,
                      left_x+side_center_r, left_y+side_center_r],
                    fill=VERY_LIGHT_PINK)
        
        # Right flower
        right_x, right_y = int(145*scale), int(85*scale)
        draw.ellipse([right_x-side_flower_r, right_y-side_flower_r,
                      right_x+side_flower_r, right_y+side_flower_r],
                    fill=LIGHT_PINK)
        draw.ellipse([right_x-side_center_r, right_y-side_center_r,
                      right_x+side_center_r, right_y+side_center_r],
                    fill=VERY_LIGHT_PINK)
        
        # Top flowers
        top_left_x, top_left_y = int(70*scale), int(62*scale)
        draw.ellipse([top_left_x-int(10*scale), top_left_y-int(10*scale),
                      top_left_x+int(10*scale), top_left_y+int(10*scale)],
                    fill=LIGHT_PINK)
        draw.ellipse([top_left_x-int(6*scale), top_left_y-int(6*scale),
                      top_left_x+int(6*scale), top_left_y+int(6*scale)],
                    fill=PINK)
        
        top_right_x, top_right_y = int(130*scale), int(62*scale)
        draw.ellipse([top_right_x-int(10*scale), top_right_y-int(10*scale),
                      top_right_x+int(10*scale), top_right_y+int(10*scale)],
                    fill=LIGHT_PINK)
        draw.ellipse([top_right_x-int(6*scale), top_right_y-int(6*scale),
                      top_right_x+int(6*scale), top_right_y+int(6*scale)],
                    fill=PINK)
        
        # Save image
        img.save(output_path)
        return True
        
    except ImportError:
        print("Pillow not available. Install with: pip install pillow")
        return False
    except Exception as e:
        print(f"Error creating icon: {e}")
        return False

def main():
    import os
    
    print("🎀 Buket.id PNG Icon Generator")
    print()
    
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
        print(f"Generating {size}x{size}px icon ({dpi})...")
        
        if create_bouquet_icon(size, output_path):
            success_count += 1
            print(f"  ✓ Created: {output_path}")
        else:
            print(f"  ✗ Failed")
        print()
    
    print(f"\n✓ Successfully generated {success_count}/{len(sizes)} icon variants")
    
    if success_count == len(sizes):
        print("\n✅ All icons generated successfully!")
        print("Run 'flutter clean && flutter run' to see the new launcher icon")
        return True
    else:
        return False

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
