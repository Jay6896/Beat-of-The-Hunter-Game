shader_type canvas_item;

// The ORIGINAL colors of the base snake (Red/Purple)
uniform vec4 old_color_1 : source_color = vec4(0.145, 0.075, 0.102, 1.0); // #25131a
uniform vec4 old_color_2 : source_color = vec4(0.816, 0.098, 0.275, 1.0); // #d01946
uniform vec4 old_color_3 : source_color = vec4(0.322, 0.231, 0.251, 1.0); // #523b40
uniform vec4 old_color_4 : source_color = vec4(0.910, 0.267, 0.267, 1.0); // #e84444


// The NEW colors you just provided! (Yellow/Olive)
uniform vec4 new_color_1 : source_color = vec4(0.149, 0.145, 0.078, 1.0); // #262514
uniform vec4 new_color_2 : source_color = vec4(0.784, 0.820, 0.098, 1.0); // #C8D119
uniform vec4 new_color_3 : source_color = vec4(0.314, 0.322, 0.231, 1.0); // #50523B
uniform vec4 new_color_4 : source_color = vec4(0.910, 0.855, 0.263, 1.0); // #E8DA43

// How strict the color matching should be
uniform float tolerance : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec4 current_pixel = texture(TEXTURE, UV);
    
    // Check if the current pixel matches any of our old colors (ignoring transparent pixels)
    if (distance(current_pixel.rgb, old_color_1.rgb) < tolerance && current_pixel.a > 0.0) {
        current_pixel.rgb = new_color_1.rgb;
    } else if (distance(current_pixel.rgb, old_color_2.rgb) < tolerance && current_pixel.a > 0.0) {
        current_pixel.rgb = new_color_2.rgb;
    } else if (distance(current_pixel.rgb, old_color_3.rgb) < tolerance && current_pixel.a > 0.0) {
        current_pixel.rgb = new_color_3.rgb;
    } else if (distance(current_pixel.rgb, old_color_4.rgb) < tolerance && current_pixel.a > 0.0) {
        current_pixel.rgb = new_color_4.rgb;
    }
    
    COLOR = current_pixel;
}