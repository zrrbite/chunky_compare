require 'chunky_png'

# === Config ===
image_a_path = 'golden.png'
image_b_path = 'actual.png'
output_path  = 'diff.png'
compare_alpha = true
box_merge_distance = 5

# === Load Images ===
img_a = ChunkyPNG::Image.from_file(image_a_path)
img_b = ChunkyPNG::Image.from_file(image_b_path)

raise "Image dimensions do not match!" unless img_a.dimension == img_b.dimension

width, height = img_a.width, img_a.height
diff_img = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)

diff_coords = []

height.times { |y|
  width.times { |x|
    a = img_a[x, y]
    b = img_b[x, y]

    diff = if compare_alpha
      a != b
    else
      ChunkyPNG::Color.r(a) != ChunkyPNG::Color.r(b) ||
      ChunkyPNG::Color.g(a) != ChunkyPNG::Color.g(b) ||
      ChunkyPNG::Color.b(a) != ChunkyPNG::Color.b(b)
    end

    if diff
      diff_img[x, y] = ChunkyPNG::Color.rgba(255, 0, 0, 255)
      diff_coords << [x, y]
    end
  }
}

# === Bounding Box Clustering ===
def merge_boxes(points, merge_distance)
  boxes = []

  points.each { |x, y|
    added = false

    boxes.each { |box|
      bx, by, bx2, by2 = box
      if (x >= bx - merge_distance && x <= bx2 + merge_distance) &&
         (y >= by - merge_distance && y <= by2 + merge_distance)
        box[0] = [bx, x].min
        box[1] = [by, y].min
        box[2] = [bx2, x].max
        box[3] = [by2, y].max
        added = true
        break
      end
    }

    boxes << [x, y, x, y] unless added
  }

  boxes
end

boxes = merge_boxes(diff_coords, box_merge_distance)

# === Draw boxes on diff image ===
boxes.each { |x1, y1, x2, y2|
  (x1..x2).each { |x|
    diff_img[x, y1] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
    diff_img[x, y2] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
  }
  (y1..y2).each { |y|
    diff_img[x1, y] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
    diff_img[x2, y] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
  }
}

percent_changed = 100.0 * diff_coords.size / (width * height)

puts "#{diff_coords.size} pixels differed (#{percent_changed.round(2)}%)"
puts "Found #{boxes.size} bounding box#{'es' if boxes.size != 1}"
diff_img.save(output_path)
puts "Diff image saved to #{output_path}"