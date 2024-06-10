#include <iostream>
#include <chrono>
#include <thread>
#include <time.h>
#include <float.h>
#include <curand_kernel.h>
#include <GLFW/glfw3.h>
#include "include/cuda/vec3.h"
#include "include/cuda/ray.h"
#include "include/cuda/sphere.h"
#include "include/cuda/hitable_list.h"
#include "include/cuda/camera.h"
#include "include/cuda/material.h"

// limited version of checkCudaErrors from helper_cuda.h in CUDA examples
#define checkCudaErrors(val) check_cuda((val), #val, __FILE__, __LINE__)

void check_cuda(cudaError_t result, char const *const func, const char *const file, int const line) {
    if (result) {
        std::cerr << "CUDA error = " << static_cast<unsigned int>(result) << " at " <<
            file << ":" << line << " '" << func << "' \n";
        cudaDeviceReset();
        exit(99);
    }
}

__device__ vec3 color(const ray& r, hitable **world, curandState *local_rand_state) {
    ray cur_ray = r;
    vec3 cur_attenuation = vec3(1.0,1.0,1.0);
    for(int i = 0; i < 50; i++) {
        hit_record rec;
        if ((*world)->hit(cur_ray, 0.001f, FLT_MAX, rec)) {
            ray scattered;
            vec3 attenuation;
            if(rec.mat_ptr->scatter(cur_ray, rec, attenuation, scattered, local_rand_state)) {
                cur_attenuation *= attenuation;
                cur_ray = scattered;
            }
            else {
                return vec3(0.0,0.0,0.0);
            }
        }
        else {
            vec3 unit_direction = unit_vector(cur_ray.direction());
            float t = 0.5f*(unit_direction.y() + 1.0f);
            vec3 c = (1.0f-t)*vec3(1.0, 1.0, 1.0) + t*vec3(0.5, 0.7, 1.0);
            return cur_attenuation * c;
        }
    }
    return vec3(0.0,0.0,0.0); // exceeded recursion
}

__global__ void rand_init(curandState *rand_state) {
    if (threadIdx.x == 0 && blockIdx.x == 0) {
        curand_init(1984, 0, 0, rand_state);
    }
}

__global__ void render_init(int max_x, int max_y, curandState *rand_state) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int j = threadIdx.y + blockIdx.y * blockDim.y;
    if((i >= max_x) || (j >= max_y)) return;
    int pixel_index = j*max_x + i;
    curand_init(1984+pixel_index, 0, 0, &rand_state[pixel_index]);
}

__global__ void render(vec3 *fb, int max_x, int max_y, int ns, camera **cam, hitable **world, curandState *rand_state) {
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int j = threadIdx.y + blockIdx.y * blockDim.y;
    if((i >= max_x) || (j >= max_y)) return;
    int pixel_index = j*max_x + i;
    curandState local_rand_state = rand_state[pixel_index];
    vec3 col(0,0,0);
    for(int s=0; s < ns; s++) {
        float u = float(i + curand_uniform(&local_rand_state)) / float(max_x);
        float v = float(j + curand_uniform(&local_rand_state)) / float(max_y);
        ray r = (*cam)->get_ray(u, v, &local_rand_state);
        col += color(r, world, &local_rand_state);
    }
    rand_state[pixel_index] = local_rand_state;
    col /= float(ns);
    col[0] = sqrt(col[0]);
    col[1] = sqrt(col[1]);
    col[2] = sqrt(col[2]);
    fb[pixel_index] = col;
}

#define RND (curand_uniform(&local_rand_state))

__global__ void create_world(hitable **d_list, hitable **d_world, curandState *rand_state, int num_spheres) {
    if (threadIdx.x == 0 && blockIdx.x == 0) {
        curandState local_rand_state = *rand_state;

        // Ground sphere
        d_list[0] = new sphere(vec3(0,-1000.0,-1), 1000, new lambertian(vec3(0.5, 0.5, 0.5)));

        // Add user-defined spheres
        for (int i = 1; i <= num_spheres; ++i) {
            float choose_mat = RND;
            vec3 center(RND * 10 - 5, 0.2, RND * 10 - 5);
            if (choose_mat < 0.8f) {
                d_list[i] = new sphere(vec3(RND * 10 - 5, 0.8, RND * 10 - 5), 0.8, new lambertian(vec3(RND * RND, RND * RND, RND * RND)));
            } else if (choose_mat < 0.95f) {
                d_list[i] = new sphere(center, 0.4, new metal(vec3(0.5f * (1.0f + RND), 0.5f * (1.0f + RND), 0.5f * (1.0f + RND)), 0.5f * RND));
            } else {
                d_list[i] = new sphere(center, 0.2, new dielectric(1.5));
            }
        }

        *rand_state = local_rand_state;
        *d_world = new hitable_list(d_list, num_spheres + 1);
    }
}

__global__ void create_camera(camera **d_camera, int nx, int ny, float angle) {
    if (threadIdx.x == 0 && blockIdx.x == 0) {
        vec3 lookfrom(13 * cos(angle), 2, 13 * sin(angle));
        vec3 lookat(0, 0, 0);
        float dist_to_focus = 10.0; // (lookfrom - lookat).length();
        float aperture = 0.1;
        *d_camera = new camera(lookfrom, lookat, vec3(0, 1, 0), 30.0, float(nx) / float(ny), aperture, dist_to_focus);
    }
}

__global__ void free_world(hitable **d_list, hitable **d_world, camera **d_camera, int num_spheres) {
    for(int i=0; i < num_spheres + 1; i++) {
        delete ((sphere *)d_list[i])->mat_ptr;
        delete d_list[i];
    }
    delete *d_world;
    delete *d_camera;
}

void update_texture(unsigned char* image, vec3 *fb, int width, int height) {
    for (int j = 0; j < height; ++j) {
        for (int i = 0; i < width; ++i) {
            size_t pixel_index = j * width + i;
            int ir = int(255.99 * fb[pixel_index].r());
            int ig = int(255.99 * fb[pixel_index].g());
            int ib = int(255.99 * fb[pixel_index].b());
            image[3 * pixel_index + 0] = ir;
            image[3 * pixel_index + 1] = ig;
            image[3 * pixel_index + 2] = ib;
        }
    }
}

int main() {
    int nx = 1200;
    int ny = 800;
    int ns = 10;
    int tx = 8;
    int ty = 8;
    int num_spheres;

    // User input for number of spheres
    std::cout << "Enter the number of spheres to render: ";
    std::cin >> num_spheres;

    // User input for frames per second
    int fps;
    std::cout << "Enter the desired frames per second: ";
    std::cin >> fps;

    if (!glfwInit()) {
        std::cerr << "Failed to initialize GLFW" << std::endl;
        return -1;
    }

    GLFWwindow* window = glfwCreateWindow(nx, ny, "CUDA Path Tracer", NULL, NULL);
    if (!window) {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }

    glfwMakeContextCurrent(window);
    glEnable(GL_TEXTURE_2D);

    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    unsigned char* image = new unsigned char[nx * ny * 3];

    std::cerr << "Rendering a " << nx << "x" << ny << " image with " << ns << " samples per pixel ";
    std::cerr << "in " << tx << "x" << ty << " blocks.\n";

    int num_pixels = nx * ny;
    size_t fb_size = num_pixels * sizeof(vec3);

    // allocate FB
    vec3* fb;
    checkCudaErrors(cudaMallocManaged((void**)&fb, fb_size));

    // allocate random state
    curandState* d_rand_state;
    checkCudaErrors(cudaMalloc((void**)&d_rand_state, num_pixels * sizeof(curandState)));
    curandState* d_rand_state2;
    checkCudaErrors(cudaMalloc((void**)&d_rand_state2, 1 * sizeof(curandState)));

    // we need that 2nd random state to be initialized for the world creation
    rand_init<<<1, 1>>>(d_rand_state2);
    checkCudaErrors(cudaGetLastError());
    checkCudaErrors(cudaDeviceSynchronize());

    // allocate memory for world and camera
    hitable** d_list;
    checkCudaErrors(cudaMalloc((void**)&d_list, (num_spheres + 1) * sizeof(hitable*))); // +1 for the ground sphere
    hitable** d_world;
    checkCudaErrors(cudaMalloc((void**)&d_world, sizeof(hitable*)));
    camera** d_camera;
    checkCudaErrors(cudaMalloc((void**)&d_camera, sizeof(camera*)));

    // Create our world of hitables once
    create_world<<<1, 1>>>(d_list, d_world, d_rand_state2, num_spheres);
    checkCudaErrors(cudaGetLastError());
    checkCudaErrors(cudaDeviceSynchronize());

    auto frame_duration = std::chrono::milliseconds(1000 / fps);

    for (int frame = 0; !glfwWindowShouldClose(window); ++frame) {
        auto frame_start = std::chrono::high_resolution_clock::now();
        float angle = 2.0f * M_PI * frame / fps;

        // Update camera position
        create_camera<<<1, 1>>>(d_camera, nx, ny, angle);
        checkCudaErrors(cudaGetLastError());
        checkCudaErrors(cudaDeviceSynchronize());

        clock_t start, stop;
        start = clock();
        // Render our buffer
        dim3 blocks(nx / tx + 1, ny / ty + 1);
        dim3 threads(tx, ty);
        render_init<<<blocks, threads>>>(nx, ny, d_rand_state);
        checkCudaErrors(cudaGetLastError());
        checkCudaErrors(cudaDeviceSynchronize());
        render<<<blocks, threads>>>(fb, nx, ny, ns, d_camera, d_world, d_rand_state);
        checkCudaErrors(cudaGetLastError());
        checkCudaErrors(cudaDeviceSynchronize());
        stop = clock();
        double timer_seconds = ((double)(stop - start)) / CLOCKS_PER_SEC;
        std::cerr << "Frame " << frame << " took " << timer_seconds << " seconds.\n";

        // Update OpenGL texture
        update_texture(image, fb, nx, ny);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, nx, ny, 0, GL_RGB, GL_UNSIGNED_BYTE, image);
        glClear(GL_COLOR_BUFFER_BIT);
        glBegin(GL_QUADS);
        glTexCoord2f(0.0f, 0.0f);
        glVertex2f(-1.0f, -1.0f);
        glTexCoord2f(1.0f, 0.0f);
        glVertex2f(1.0f, -1.0f);
        glTexCoord2f(1.0f, 1.0f);
        glVertex2f(1.0f, 1.0f);
        glTexCoord2f(0.0f, 1.0f);
        glVertex2f(-1.0f, 1.0f);
        glEnd();
        glfwSwapBuffers(window);
        glfwPollEvents();

        auto frame_end = std::chrono::high_resolution_clock::now();
        std::chrono::duration<double, std::milli> frame_time = frame_end - frame_start;
        if (frame_time < frame_duration) {
            std::this_thread::sleep_for(frame_duration - frame_time);
        }
    }

    // clean up
    checkCudaErrors(cudaDeviceSynchronize());

    // Free world objects
    free_world<<<1, 1>>>(d_list, d_world, d_camera, num_spheres);
    checkCudaErrors(cudaGetLastError());
    checkCudaErrors(cudaDeviceSynchronize());

    checkCudaErrors(cudaFree(d_camera));
    checkCudaErrors(cudaFree(d_world));
    checkCudaErrors(cudaFree(d_list));
    checkCudaErrors(cudaFree(d_rand_state));
    checkCudaErrors(cudaFree(d_rand_state2));
    checkCudaErrors(cudaFree(fb));

    delete[] image;
    glfwDestroyWindow(window);
    glfwTerminate();

    cudaDeviceReset();
    return 0;
}
