import os
from PIL import Image

def process_image(input_path, output_path, target_width=1440, target_height=720):
    try:
        # 打开图片
        img = Image.open(input_path)
        
        # 创建新的背景图（黑色）
        new_img = Image.new('RGB', (target_width, target_height), (0, 0, 0))
        
        # 计算缩放比例，保持原图比例
        width_ratio = target_width / img.width
        height_ratio = target_height / img.height
        
        # 选择较小的比例以确保图片完全放入且不裁剪
        scale = min(width_ratio, height_ratio)
        
        # 如果原图比目标尺寸小，可以选择不放大，或者放大到合适大小
        # 这里假设我们希望图片尽可能大但保持在框内
        
        new_w = int(img.width * scale)
        new_h = int(img.height * scale)
        
        # 如果计算出的尺寸大于原图，且原图较小，是否要放大？
        # 通常Hero Image需要清晰，如果原图太小放大可能会模糊。
        # 但为了填满布局，我们还是按比例缩放。
        
        # 高质量缩放
        resized_img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # 计算粘贴位置（居中）
        x = (target_width - new_w) // 2
        y = (target_height - new_h) // 2
        
        # 粘贴
        new_img.paste(resized_img, (x, y))
        
        # 保存
        new_img.save(output_path, quality=95)
        print(f"Success: {input_path} -> {output_path}")
        
    except Exception as e:
        print(f"Error processing {input_path}: {str(e)}")

# 处理列表
images = [
    ('docs/image/2.jpg', 'docs/image/hero_2.jpg'),
    ('docs/image/3.jpg', 'docs/image/hero_3.jpg'),
    ('docs/image/1.jpg', 'docs/image/hero_1.jpg') # 假设截图4对应的是1.jpg，根据find结果猜测
]

# 检查文件是否存在，如果不存在尝试匹配其他可能的命名
# 根据find结果，我们有 1.jpg, 2.jpg, 3.jpg
# 用户说 "截图二至四"，通常对应 2, 3, 4。但find只看到了 1, 2, 3。
# 也许用户是指 1.jpg, 2.jpg, 3.jpg 这三个文件？
# 让我们先处理这三个。

for src, dst in images:
    if os.path.exists(src):
        process_image(src, dst)
    else:
        print(f"File not found: {src}")
