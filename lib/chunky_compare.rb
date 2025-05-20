require 'chunky_png'

class ChunkyCompare
  attr_reader :golden_path, :actual_path, :output_path, :compare_alpha, :box_merge_distance

  def initialize(golden:, actual:, output:, alpha: true, box_distance: 5)
    @golden_path = golden
    @actual_path = actual
    @output_path = output
    @compare_alpha = alpha
    @box_merge_distance = box_distance
  end

  def run
    img_a = ChunkyPNG::Image.from_file(golden_path)
    img_b = ChunkyPNG::Image.from_file(actual_path)

    raise "Image sizes do not match!" unless img_a.dimension == img_b.dimension

    width, height = img_a.width, img_a.height
    diff_img = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)

    changed_pixels = []

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
          changed_pixels << [x, y]
        end
      }
    }

    boxes = merge_boxes(changed_pixels, box_merge_distance)

    draw_boxes(diff_img, boxes)

    diff_img.save(output_path)
    puts "✅ #{changed_pixels.size} pixels differed (#{percent(changed_pixels.size, width * height)}%)"
    puts "📦 Found #{boxes.size} bounding boxes"
    puts "🖼️  Saved to #{output_path}"
  end

  private

  def merge_boxes(points, distance)
    boxes = []

    points.each { |x, y|
      added = false

      boxes.each { |box|
        bx, by, bx2, by2 = box
        if (x >= bx - distance && x <= bx2 + distance) &&
           (y >= by - distance && y <= by2 + distance)
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

  def draw_boxes(image, boxes)
    boxes.each { |x1, y1, x2, y2|
      (x1..x2).each { |x|
        image[x, y1] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
        image[x, y2] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
      }
      (y1..y2).each { |y|
        image[x1, y] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
        image[x2, y] = ChunkyPNG::Color.rgba(0, 255, 0, 255)
      }
    }
  end

  def percent(changed, total)
    ((100.0 * changed) / total).round(2)
  end
end