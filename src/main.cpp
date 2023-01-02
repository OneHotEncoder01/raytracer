/**
 * @copyright OneHotEncoder
 * @author    Sinan oetuek
 * @file      
 * @brief     
 */
#include "header/rtweekend.h"
#include "header/camera.h"
#include "header/color.h"
#include "header/hittable_list.h"
#include "header/sphere.h"
#include "header/material.h"

#include <sstream>
#include <fstream>
#include <iostream>


color ray_color(const ray& r, const hittable& world, int depth) {
    hit_record rec;

    // If we've exceeded the ray bounce limit, no more light is gathered.
    if (depth <= 0)
        return color(0,0,0);

    if (world.hit(r, 0.001, infinity, rec)) {
        ray scattered;
        color attenuation;
        if (rec.mat_ptr->scatter(r, rec, attenuation, scattered))
            return attenuation * ray_color(scattered, world, depth-1);
        return color(0,0,0);
    }

    vec3 unit_direction = unit_vector(r.direction());
    auto t = 0.5*(unit_direction.y() + 1.0);
    return (1.0-t)*color(1.0, 1.0, 1.0) + t*color(0.5, 0.7, 1.0);
}

void Render(const std::string& str, int pos){
 
   // Image
   

    std::ofstream out(str);


    const auto aspect_ratio = 16.0 / 9.0;
    const int image_width = 200;
    const int image_height = static_cast<int>(image_width / aspect_ratio);
    const int samples_per_pixel = 100;
    const int max_depth = 50;
    
    // World
    hittable_list world;

    auto material_ground = make_shared<lambertian>(color(0.8, 0.8, 0.0));
    auto material_center = make_shared<lambertian>(color(0.1, 0.2, 0.5));
    auto material_right  = make_shared<metal>(color(0.8, 0.6, 0.2), 0.0);

    world.add(make_shared<sphere>(point3( 0.0, -100.5, -1.0), 100.0, material_ground));
    world.add(make_shared<sphere>(point3( 0.0,    0.0, -1.0),   0.5, material_center));
    world.add(make_shared<sphere>(point3( 1.0,    0.0, -1.0),   0.5, material_right));

    // Camera

    camera cam(point3(-2 + pos ,2 + pos,1), point3(0,0,-1), vec3(0,1,0), 90, aspect_ratio);
    
    out << "P3" << std::endl;
    out << image_width << " " << image_height << "\n255" << std::endl;

    for (int j = image_height-1; j >= 0; --j) {
        std::cerr << "\rScanlines remaining: " << j << " frame number:" << i << ' ' << std::flush;
        for (int i = 0; i < image_width; ++i) {
            color pixel_color(0, 0, 0);
            for (int s = 0; s < samples_per_pixel; ++s) {
                auto u = (i + random_double()) / (image_width-1);
                auto v = (j + random_double()) / (image_height-1);
                ray r = cam.get_ray(u, v);
                pixel_color += ray_color(r, world, max_depth);
            }
            write_color(out, pixel_color, samples_per_pixel);
        }
    }
}



int main() {

   // Render
   int n = 0;
   for(int i = -5; i < 5 ; ++i){
           n++;
           std::stringstream ss;
           ss << n;
           std::string str = "frames/" + ss.str() + ".ppm";
           Render(str, i);
   }
    std::cerr << "\nDone.\n";

}
